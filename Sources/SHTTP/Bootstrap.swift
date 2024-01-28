//
//  Bootstrap.swift
//  snake-http
//
//  Created by Tiger on 11/14/22.
//

import NIO
import NIOHTTP2

public final class Bootstrap {
    
    internal let handler: HandlerMapping
    
    public let configuration: Configuration
    
    public let eventLoopGroup: EventLoopGroup
    
    public private(set) var channelFuture: EventLoopFuture<Channel>?
    
    public init(configuration: Configuration, eventLoopGroup: MultiThreadedEventLoopGroup) {
        self.configuration = configuration
        self.eventLoopGroup = eventLoopGroup
        self.handler = .init(configuration: configuration.handler)
    }
    
    deinit {
        if let channel = try? channelFuture?.wait() {
            channel.close(mode: .all, promise: nil)
        }
    }
    
    public var onClose: EventLoopFuture<Void> {
        guard let channel = try? channelFuture?.wait() else {
            fatalError("Called onClose before start()")
        }
        return channel.closeFuture
    }
    
    public func start() -> EventLoopFuture<Channel> {
        if let channel = try? channelFuture?.wait() {
            channel.close(mode: .all, promise: nil)
        }
        
        let socketBootstrap = ServerBootstrap(group: eventLoopGroup)
            // Specify backlog and enable SO_REUSEADDR for the server itself
            .serverChannelOption(ChannelOptions.backlog, value: configuration.backlog)
            .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: configuration.reuseAddr ? 1 : 0)
            
            // Set the handlers that are applied to the accepted Channels
            .childChannelInitializer { channel -> EventLoopFuture<Void> in
                channel.pipeline.configureHTTPServerPipeline(withErrorHandling: true).flatMap {
                    channel.pipeline.addHandlers([
                        PipelineRequestHandler(bootstrap: self),
                        PipelineResponseHandler(bootstrap: self),
                        HandlePipeline(bootstrap: self),
                    ])
                }
            }

            // Enable SO_REUSEADDR for the accepted Channels
            .childChannelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: configuration.tcpNoDelay ? 1 : 0)
            .childChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: configuration.reuseAddr ? 1 : 0)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 1)
            .childChannelOption(ChannelOptions.allowRemoteHalfClosure, value: configuration.allowHalfClosure)
     
        let channelFuture = socketBootstrap.bind(host: configuration.host, port: configuration.port)
        self.channelFuture = channelFuture
        return channelFuture
    }
}

extension Bootstrap {
    
    public func register(mappings: MappingProtocol...) {
        if configuration.handler.registrable {
            handler.register(mappings: mappings)
        }
    }
}

extension Bootstrap {
    
    public struct Configuration {
        
        public struct HandlerMappingConfiguration {
            
            public let initialization: Bool
            public let registrable: Bool
            
            public init(initialization: Bool = true, registrable: Bool = false) {
                self.initialization = initialization
                self.registrable = registrable
            }
        }
        
        public var host: String
        public var port: Int
        public var backlog: Int32
        public var reuseAddr: Bool
        public var tcpNoDelay: Bool
        public var allowHalfClosure: Bool
        public var handler: HandlerMappingConfiguration
        public var logger: String
        
        public init(host: String = "localhost",
                    port: Int = 8888,
                    backlog: Int32 = 256,
                    reuseAddr: Bool = true,
                    tcpNoDelay: Bool = true,
                    allowHalfClosure: Bool = false,
                    handler: HandlerMappingConfiguration = .init(),
                    logger: String = "/dev/null/") {
            
            self.host = host
            self.port = port
            self.backlog = backlog
            self.reuseAddr = reuseAddr
            self.tcpNoDelay = tcpNoDelay
            self.allowHalfClosure = allowHalfClosure
            self.handler = handler
            self.logger = logger
        }
    }
}

extension Bootstrap {
    
    public func printAddress() {
        let configuration = configuration
        channelFuture?.whenComplete { result in
            switch result {
            case .success(let channel):
                if let address = channel.localAddress {
                    let host: String
                    let `protocol`: String
                    switch address {
                    case .v4(let ip):
                        host = ip.host + (address.port.map { ":\($0)" } ?? "")
                        `protocol` = "ipv4"
                    case .v6(let ip):
                        host = ip.host + (address.port.map { ":\($0)" } ?? "")
                        `protocol` = "ipv6"
                    default:
                        host = "?"
                        `protocol` = "?"
                        print("unknown protocol\(address)")
                    }
                    print("Server started and listening on [\(`protocol`)] http://\(host), logger path \(configuration.logger)")
                } else {
                    print("Address was unable to bind. Please check that the socket was not closed or that the address family was understood.")
                }
            case .failure(let error):
                print(error)
                print("Address was unable to bind. Please check that the socket was not closed or that the address family was understood.")
            }
        }
    }
}

