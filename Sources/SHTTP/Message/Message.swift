//
//  Message.swift
//  snake-http
//
//  Created by panghu on 7/5/20.
//

import NIO
import NIOHTTP1
import Foundation

public struct Message {
    
    public let request: MessageRequest
    public let response: MessageResponse
}

public struct MessageUri {
    
    public let path: String
    public let query: String
    public let queryItems: [String: [String]]
    
    init(head: HTTPRequestHead) {
        var queryItems: [String: [String]] = [:]
        let urlComponents = URLComponents(string: head.uri)
        for item in urlComponents?.queryItems ?? []  {
            let items = queryItems[item.name] ?? []
            if let value = item.value {
                queryItems[item.name] = items + [value]
            }
        }
        self.path = urlComponents?.path ?? "/"
        self.query = urlComponents?.query ?? ""
        self.queryItems = queryItems
    }
}

public struct MessageRequest {
    
    public let head: HTTPRequestHead
    public let uri: MessageUri
    public let body: MessageBody
    
    public init(head: HTTPRequestHead, stream: MessageByteStream) {
        self.head = head
        self.uri = MessageUri(head: head)
        self.body = MessageBody(stream: stream)
    }
    
    public init(head: HTTPRequestHead, body: MessageBody = MessageBody()) {
        self.head = head
        self.uri = MessageUri(head: head)
        self.body = body
    }
}

public struct MessageResponse {

    public let head: HTTPResponseHead
    public let body: MessageBody
    
    public init(head: HTTPResponseHead, stream: MessageByteStream) {
        self.head = head
        self.body = MessageBody(stream: stream)
    }
    
    public init(head: HTTPResponseHead, body: MessageBody = MessageBody()) {
        self.head = head
        self.body = body
    }
}

public typealias MessageHandler = (_ request: MessageRequest, _ channel: Channel) -> EventLoopFuture<MessageResponse>

public protocol MessageDelegate {
    init()
    func respond(from request: MessageRequest, on channel: Channel) -> EventLoopFuture<MessageResponse>
}

func MessageRespond(from request: MessageRequest, on channel: Channel) -> EventLoopFuture<MessageResponse> {
    let promise = channel.eventLoop.makePromise(of: MessageResponse.self)
    let response = MessageResponse(head: .init(version: .init(major: 2, minor: 0), status: .notFound), body: MessageBody(string: messageBody404HTML))
    promise.succeed(response)
    return promise.futureResult
}

internal let messageBody404String: String = "Not Found 404."

internal let messageBody404Json: [String : Any] = [
    "data": "null",
    "code": 404
    ]

internal let messageBody404HTML: String = """
<!DOCTYPE html>
<html lang=en>
<meta charset=utf-8>
<title>Error 404 (Not Found)!!</title>
<p><b>404.</b> <ins>That’s an error.</ins>
<p>The requested URL <code>/404</code> was not found on this server.
</html>
"""
