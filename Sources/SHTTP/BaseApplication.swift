//
//  BaseController.swift
//  snake-http
//
//  Created by Tiger on 11/14/22.
//

import NIO
import NIOHTTP1
import Foundation

open class BaseController {
    
    public class var request: String { "/" }
    
    public required init() {
        
    }
    
    open func respond(from request: MessageRequest, on channel: Channel) -> EventLoopFuture<MessageResponse> {
        let promise = channel.eventLoop.makePromise(of: MessageResponse.self)
        let response = MessageResponse(head: .init(version: .init(major: 2, minor: 0), status: .ok), body: .init(json: []))
        promise.succeed(response)
        return promise.futureResult
    }
}

class UserController: BaseController {
    
    override class var request: String {
        return ""
    }
}

extension BaseController {
    
    internal class Responser {
        
        func controller(message: MessageRequest) -> BaseController {
            let controllers = BaseController.Responser.controllers.map {
                let children = Mirror(reflecting: $0.init()).children
                children.forEach { child in
                    print(child.label)
                    print(child.value)
                }
            }
            
//            print(controllers)
            return BaseController()
        }
    }
}

extension BaseController.Responser {
    
    static let controllers: [BaseController.Type] = allControllers()
    
    private static func allControllers() -> [BaseController.Type] {
        func class_isController(_ `class`: AnyClass?) -> Bool {
            var `class`: AnyClass? = `class`
            while let any = class_getSuperclass(`class`) {
                if BaseController.self === `class` {
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
        return classes.map { `class` -> BaseController.Type? in
            guard class_isController(`class`) else {
                return nil
            }
            guard let application = `class` as? BaseController.Type else {
                return nil
            }
            return application
        }.compactMap { $0 }
    }
}
