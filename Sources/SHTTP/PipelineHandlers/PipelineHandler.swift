//
//  PipelineHandler.swift
//  snake-http
//
//  Created by panghu on 7/10/20.
//

final class HandlePipeline: ChannelInboundHandler {
    
    typealias InboundIn = MessageRequest
    typealias OutboundOut = Message
    
    let bootstrap: Bootstrap
    
    init(bootstrap: Bootstrap) {
        self.bootstrap = bootstrap
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let wrapOutOut = wrapOutboundOut
        let request = unwrapInboundIn(data)
        let respond = bootstrap.urlPatterns.respond(path: request.uri.path)
        respond(request, context.channel).whenComplete { result in
            switch result {
            case .success(let response):
                context.write(wrapOutOut(Message(request: request, response: response)), promise: nil)
            case .failure(_):
                context.close(promise: nil)
            }
        }
    }
}
