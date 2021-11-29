//
//  PipelineResponseHandler.swift
//  snake-http
//
//  Created by panghu on 7/10/20.
//

import Foundation

final class PipelineResponseHandler: ChannelOutboundHandler, RemovableChannelHandler {
    
    typealias OutboundIn = Message
    typealias OutboundOut = HTTPServerResponsePart
    
    let application: Application
    
    init(application: Application) {
        self.application = application
    }

    func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        let message = unwrapOutboundIn(data)
        
        print("[\(debugDate)] [\(message.request.head.method.rawValue)] [\(message.response.head.status.code)] \"\(message.request.head.uri)\"")
        context.write(wrapOutboundOut(.head(message.response.head)), promise: promise)
        switch message.response.body.storage {
        case .empty:
            write(context: context, response: message.response, promise: promise)
        case .buffer(let buffer):
            write(context: context, response: message.response, buffer: buffer, promise: promise)
        case .data(let data):
            write(context: context, response: message.response, data: data, promise: promise)
        case .string(let string):
            write(context: context, response: message.response, string: string, promise: promise)
        case .json(let json):
            write(context: context, response: message.response, json: json, promise: promise)
        case .stream(let stream):
            write(context: context, response: message.response, stream: stream, promise: promise)
        }
        context.writeAndFlush(wrapOutboundOut(.end(nil)), promise: promise)
    }
    
    private func write(context: ChannelHandlerContext, response: MessageResponse, promise: EventLoopPromise<Void>?) {
        
    }
    
    private func write(context: ChannelHandlerContext, response: MessageResponse, buffer: ByteBuffer, promise: EventLoopPromise<Void>?) {
        context.write(wrapOutboundOut(.body(.byteBuffer(buffer))), promise: promise)
    }
    
    private func write(context: ChannelHandlerContext, response: MessageResponse, data: Data, promise: EventLoopPromise<Void>?) {
        var buffer = context.channel.allocator.buffer(capacity: data.count)
        buffer.writeBytes(data)
        context.write(wrapOutboundOut(.body(.byteBuffer(buffer))), promise: promise)
    }
    
    private func write(context: ChannelHandlerContext, response: MessageResponse, string: String, promise: EventLoopPromise<Void>?) {
        var buffer = context.channel.allocator.buffer(capacity: string.count)
        buffer.writeString(string)
        context.write(wrapOutboundOut(.body(.byteBuffer(buffer))), promise: promise)
    }
    
    private func write(context: ChannelHandlerContext, response: MessageResponse, json: Any, promise: EventLoopPromise<Void>?) {
        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
            var buffer = context.channel.allocator.buffer(capacity: data.count)
            buffer.writeBytes(data)
            context.write(wrapOutboundOut(.body(.byteBuffer(buffer))), promise: promise)
            promise?.succeed(())
        } catch {
            promise?.fail(error)
        }
    }
    
    private func write(context: ChannelHandlerContext, response: MessageResponse, stream: MessageByteStream, promise: EventLoopPromise<Void>?) {
        let wrapOutOut = wrapOutboundOut
        stream.read { _, element in
            switch element {
            case .bytes(let buffer):
                context.write(wrapOutOut(.body(.byteBuffer(buffer))), promise: promise)
            case .error(let error):
                promise?.fail(error)
            case .end(_):
                break
            }
        }
    }
}

extension PipelineResponseHandler {
 
    private static let debugDateFormatter = { () -> DateFormatter in
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .medium
        dateFormatter.locale = Locale.current
        return dateFormatter
    }()

    private static var debugDate: String {
        debugDateFormatter.string(from: Date())
    }
    
    private var debugDate: String {
        return PipelineResponseHandler.debugDate
    }

}
