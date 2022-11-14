//
//  BaseApplication.swift
//  snake-http
//
//  Created by Tiger on 11/14/22.
//

import Foundation

open class BaseApplication {
    
    public required init() {
        
    }
    
    open func respond(from request: MessageRequest, on channel: Channel) -> EventLoopFuture<MessageResponse> {
        let promise = channel.eventLoop.makePromise(of: MessageResponse.self)
        let response = MessageResponse(head: .init(version: .init(major: 2, minor: 0), status: .ok), body: .init(json: {}))
        promise.succeed(response)
        return promise.futureResult
    }
    
}

extension BaseApplication {
    
    internal class Reponse {
        
        let apps = Reponse.applications()
        
        
    }
}

extension BaseApplication.Reponse {
    
    static func applications() -> [BaseApplication.Type] {
        func class_isApplication(_ `class`: AnyClass?) -> Bool {
            var `class`: AnyClass? = `class`
            while let any = class_getSuperclass(`class`) {
                if BaseApplication.self === `class` {
                    return true
                }
                `class` = any
            }
            return false
        }
        var count: UInt32 = 0
        guard let pointer = objc_copyClassList(&count) else {
            return []
        }
        defer { free(UnsafeMutableRawPointer(pointer)) }
        let classes = UnsafeBufferPointer(start: pointer, count: Int(count))
        return classes.map { `class` -> BaseApplication.Type? in
            guard class_isApplication(`class`) else {
                return nil
            }
            guard let application = `class` as? BaseApplication.Type else {
                return nil
            }
            return application
        }.compactMap { $0 }
    }
}
