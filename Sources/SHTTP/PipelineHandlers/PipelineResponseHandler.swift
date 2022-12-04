//
//  PipelineResponseHandler.swift
//  snake-http
//
//  Created by panghu on 7/10/20.
//

import Foundation
import NIOCore
import NIOHTTP1

final class PipelineResponseHandler: ChannelOutboundHandler, RemovableChannelHandler {
    
    typealias OutboundIn = Message
    typealias OutboundOut = HTTPServerResponsePart
    
    let bootstrap: Bootstrap
    
    init(bootstrap: Bootstrap) {
        self.bootstrap = bootstrap
    }

    func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        let message = unwrapOutboundIn(data)
        let response = message.response
        let head = response.head
        
        context.write(wrapOutboundOut(.head(message.response.head)), promise: nil)
        write(context: context, head: head, body: message.response.body, response: response).whenComplete { [self] _ in
            context.writeAndFlush(wrapOutboundOut(.end(nil))).whenComplete { result in
                promise?.completeWith(result)
                context.close(promise: nil)
            }
        }
        puts(message: message, from: context.remoteAddress)
    }
    
    private func write(context: ChannelHandlerContext, head: HTTPResponseHead, body: MessageBody, response: MessageResponse) -> EventLoopFuture<Void> {
        switch body.storage {
        case .empty:
            return write(context: context)
        case .buffer(let buffer):
            return write(context: context, buffer: buffer)
        case .data(let data):
            return write(context: context, data: data)
        case .string(let string):
            return write(context: context, string: string)
        case .json(let json):
            return write(context: context, json: json)
        case .stream(let stream):
            return write(context: context, stream: stream)
        }
    }
    
    private func write(context: ChannelHandlerContext) -> EventLoopFuture<Void> {
        return context.eventLoop.makeSucceededFuture(())
    }
    
    private func write(context: ChannelHandlerContext, buffer: ByteBuffer) -> EventLoopFuture<Void> {
        return context.writeAndFlush(wrapOutboundOut(.body(.byteBuffer(buffer))))
    }
    
    private func write(context: ChannelHandlerContext, data: Data) -> EventLoopFuture<Void> {
        var buffer = context.channel.allocator.buffer(capacity: data.count)
        buffer.writeBytes(data)
        return context.writeAndFlush(wrapOutboundOut(.body(.byteBuffer(buffer))))
    }
    
    private func write(context: ChannelHandlerContext, string: String) -> EventLoopFuture<Void> {
        var buffer = context.channel.allocator.buffer(capacity: string.count)
        buffer.writeString(string)
        return context.writeAndFlush(wrapOutboundOut(.body(.byteBuffer(buffer))))
    }
    
    private func write(context: ChannelHandlerContext, json: Any) -> EventLoopFuture<Void> {
        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
            var buffer = context.channel.allocator.buffer(capacity: data.count)
            buffer.writeBytes(data)
            return context.writeAndFlush(wrapOutboundOut(.body(.byteBuffer(buffer))))
        } catch {
            return context.eventLoop.makeFailedFuture(error)
        }
    }
    
    private func write(context: ChannelHandlerContext, stream: MessageByteStream) -> EventLoopFuture<Void> {
        let wrapOutOut = wrapOutboundOut
        let promise: EventLoopPromise<Void> = context.eventLoop.makePromise()
        stream.read { _, element in
            switch element {
            case .bytes(let buffer):
                _ = context.writeAndFlush(wrapOutOut(.body(.byteBuffer(buffer))))
            case .error(let error):
                context.flush()
                promise.fail(error)
            case .end(_):
                context.flush()
                promise.succeed(())
            }
        }
        return promise.futureResult
    }
}

extension PipelineResponseHandler {
 
    private static let debugDateFormatter = { () -> DateFormatter in
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        dateFormatter.dateFormat = "MM/dd/yy,HH:mm:ss"
        return dateFormatter
    }()

    private static var debugDate: String {
        debugDateFormatter.string(from: Date())
    }

    private func puts(message: Message, from: SocketAddress?) {
        let date = Self.debugDateFormatter.string(from: Date())
        let method = message.request.head.method.rawValue
        let code = message.response.head.status.code
        let path = message.request.head.uri
        
        if let ip = message.request.head.headers.first(name: "X-Real-IP") {
            print("\(date) > [\(method)][\(code)] from: [x-real-ip:\(ip)] `\(path)`")
        } else {
            print("\(date) > [\(method)][\(code)] from: [ip:\(from?.ipAddress ?? "-")] `\(path)`")
        }
    }
}
