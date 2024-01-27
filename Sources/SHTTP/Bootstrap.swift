//
//  Bootstrap.swift
//  snake-http
//
//  Created by Tiger on 11/14/22.
//

import NIO
import NIOHTTP2

public final class Bootstrap {
    
    private var channel: Channel?
    
    public let configuration: Configuration
    public let eventLoopGroup: EventLoopGroup
    
    internal let handler: HandlerMapping
    
    public init(initialization: Bool = true, registrable: Bool = false, configuration: Configuration, eventLoopGroup: MultiThreadedEventLoopGroup) {
        self.configuration = configuration
        self.eventLoopGroup = eventLoopGroup
        self.handler = .init(initialization: initialization, registrable: registrable)
    }
    
    deinit { try? eventLoopGroup.syncShutdownGracefully() }
    
    public var localAddress: SocketAddress? {
        guard let channel = channel else {
            fatalError("Called onClose before start()")
        }
        return channel.localAddress
    }
    
    public var onClose: EventLoopFuture<Void> {
        guard let channel = channel else {
            fatalError("Called onClose before start()")
        }
        return channel.closeFuture
    }
    
    public func start() -> EventLoopFuture<Void> {
        
        let configuration = self.configuration
        let eventLoopGroup = self.eventLoopGroup
        
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
     
        return socketBootstrap.bind(host: configuration.host, port: configuration.port).map { channel in
            self.channel = channel
        }
    }
}

extension Bootstrap {
    
    public struct Configuration {
        
        public var host: String
        public var port: Int
        public var backlog: Int32
        public var reuseAddr: Bool
        public var tcpNoDelay: Bool
        public var allowHalfClosure: Bool
        public var logger: String
        
        public init(host: String = "localhost",
                    port: Int = 8888,
                    backlog: Int32 = 256,
                    reuseAddr: Bool = true,
                    tcpNoDelay: Bool = true,
                    allowHalfClosure: Bool = false,
                    logger: String = "/dev/null/") {
            
            self.host = host
            self.port = port
            self.backlog = backlog
            self.reuseAddr = reuseAddr
            self.tcpNoDelay = tcpNoDelay
            self.allowHalfClosure = allowHalfClosure
            self.logger = logger
        }
    }
}

extension Bootstrap {
    
    public func printAddress() {
        
        guard let address = localAddress else {
            print("Address was unable to bind. Please check that the socket was not closed or that the address family was understood.")
            return
        }

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
    }
}

