//
//  RequestController.swift
//  snake-http
//
//  Created by Tiger on 11/14/22.
//

import NIO
import NIOHTTP1
import Foundation

open class RequestController {
    
    public required init() {
        
    }
}

public protocol MappingProtocol {
    
    init()
    
    var mapping: String { get }
}

@propertyWrapper
public struct RequestMapping {
    
    public typealias Handler = (_ request: MessageRequest, _ channel: Channel, _ token: Token) -> EventLoopFuture<MessageResponse>
    
    public let path: String
    
    public let methods: [HTTPMethod]
    
    public let handler: Handler?
    
    public var wrappedValue: String {
        return path
    }
    
    public init(_ path: String, method: [HTTPMethod] = [], _ handler: @escaping Handler) {
        self.path = path
        self.methods = method
        self.handler = handler
    }
    
    public init(wrappedValue: String) {
        path = wrappedValue
        methods = []
        handler = nil
    }
}

final class InternalRequestController {
    
    static let messageBody404String: String = "Not Found 404."

    static let messageBody404Json: [String : Any] = [
        "data": "null",
        "code": 404
        ]

    static let messageBody404HTML: String = """
    <!DOCTYPE html>
    <html lang=en>
    <meta charset=utf-8>
    <title>Error 404 (Not Found)!!</title>
    <p><b>404.</b> <ins>That’s an error.</ins>
    <p>The requested URL <code>/404</code> was not found on this server.
    </html>
    """
    
    static func respond(from request: MessageRequest, on channel: Channel, token: RequestMapping.Token) -> EventLoopFuture<MessageResponse> {
        let promise = channel.eventLoop.makePromise(of: MessageResponse.self)
        let response = MessageResponse(head: .init(version: .init(major: 2, minor: 0), status: .ok), body: .init(json: messageBody404Json))
        promise.succeed(response)
        return promise.futureResult
    }
}
