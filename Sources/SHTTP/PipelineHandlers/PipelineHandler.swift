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
        let wrap = wrapOutboundOut
        let request = unwrapInboundIn(data)
        let result = bootstrap.handler.lookupHandlerMethod(request: request)
        result.handler(request, context.channel, result.token).whenComplete { result in
            switch result {
            case .success(let response):
                context.write(wrap(Message(request: request, response: response)), promise: nil)
            case .failure(_):
                context.close(promise: nil)
            }
        }
    }
}
