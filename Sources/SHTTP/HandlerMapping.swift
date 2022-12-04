//
//  HandlerMapping.swift
//  snake-http
//
//  Created by Tiger on 11/14/22.
//

import Foundation

final class HandlerMapping {
    
    let directPathnameMappings: [RequestMapping.Pathname: [RequestMapping.Element]]
    
    init() {
        directPathnameMappings = Self.mappings
    }
    
    func lookupHandlerMethod(request: MessageRequest) -> RequestMapping.Handler {
        let pathname: RequestMapping.Pathname = .init(path: request.uri.path)
        if let mapping = directPathnameMappings[pathname]?.first {
            return mapping.handler
        }
        return InternalRequestController.respond(from:on:)
    }
}

extension HandlerMapping {
    
    private static var mappings: [RequestMapping.Pathname: [RequestMapping.Element]] {
        controllers.map {
            (pathname: RequestMapping.Pathname(path: $0.mapping), controller: $0)
        }.sorted {
            $0.pathname > $1.pathname
        }.reduce(into: [RequestMapping.Pathname: [RequestMapping.Element]]()) { partial, items in
            let pathname = items.pathname
            Mirror(reflecting: items.controller).children.forEach {
                guard let mapping = $0.value as? RequestMapping, let handler = mapping.handler else {
                    return
                }
                let key = pathname + mapping.path
                var mappings = partial[key] ?? []
                mappings.append(.init(pathname: key, mapping: mapping, handler: handler))
                partial[key] = mappings
            }
        }
    }
    
    private static var controllers: [MappingProtocol] {
        var count: UInt32 = 0
        guard let pointer = objc_copyClassList(&count) else {
            return []
        }
        defer {
            free(UnsafeMutableRawPointer(pointer))
        }
        
        let classes = UnsafeBufferPointer(start: pointer, count: Int(count))
        return classes.map { `class` -> MappingProtocol? in
            guard let controller = classIsRequestController(`class`) as? MappingProtocol.Type else {
                return nil
            }
            return controller.init()
        }.compactMap {
            $0
        }
    }
    
    private static func classIsRequestController(_ `class`: AnyClass?) -> RequestController.Type? {
        var any: AnyClass? = `class`
        while let superclass = class_getSuperclass(any) {
            defer {
                any = superclass
            }
            guard superclass is RequestController.Type else {
                continue
            }
            guard let controller = `class` as? RequestController.Type else {
                continue
            }
            return controller
        }
        return nil
    }
}

extension RequestMapping {
    
    struct Pathname {
        
        let elements: [String]
        
        let directPath: String
    }
    
    struct Element {
        
        let pathname: Pathname
        
        let mapping: RequestMapping
        
        let handler: RequestMapping.Handler
    }
}

extension RequestMapping.Pathname: CustomDebugStringConvertible, CustomStringConvertible {
    
    var debugDescription: String {
        directPath
    }
    
    var description: String {
        directPath
    }
}

extension RequestMapping.Pathname {
    
    init(path: String) {
        elements = path.split(separator: "/").filter { !$0.isEmpty }.map(String.init)
        directPath = "/" + elements.joined(separator: "/")
    }
    
    init(lhs: Self, rhs: Self) {
        elements = lhs.elements + rhs.elements
        directPath = "/" + elements.joined(separator: "/")
    }
}

extension RequestMapping.Pathname {
    
    static func + (lhs: Self, rhs: Self) -> Self {
        return .init(lhs: lhs, rhs: rhs)
    }
    
    static func + (lhs: Self, rhs: String) -> Self {
        return .init(lhs: lhs, rhs: .init(path: rhs))
    }
}

extension RequestMapping.Pathname: Comparable, Hashable {
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.directPath == rhs.directPath
    }
    
    static func < (lhs: RequestMapping.Pathname, rhs: RequestMapping.Pathname) -> Bool {
        if lhs.elements.count == rhs.elements.count {
            return lhs.directPath < rhs.directPath
        } else {
            return lhs.elements.count < rhs.elements.count
        }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(directPath)
    }
}
