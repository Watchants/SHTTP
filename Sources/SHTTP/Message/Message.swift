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
