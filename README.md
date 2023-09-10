# snake-http 

🚀 Non-blocking, event-driven HTTP built on Swift NIO.

Installation
===

```

let package = Package(
    ...
    dependencies: [
        .package(url: "https://github.com/Watchants/snake-http.git", from: "0.1.1"),
    ],
    ...
)

```

Usage
===
### start
```
let bootstrap = Bootstrap(
    configuration: .init(host: "127.0.0.1", port: 8889),
    eventLoopGroup: .init(numberOfThreads: System.coreCount)
)
try bootstrap.start().wait()
bootstrap.printAddress()
try bootstrap.onClose.wait()
```

### adding api
```
class GettingController: RequestController, MappingProtocol {
    
    let mapping: String = "/get"
    
    @RequestMapping("", { request, channel, token in
        let promise = channel.eventLoop.makePromise(of: MessageResponse.self)
        let response = MessageResponse(head: .init(version: .init(major: 2, minor: 0), status: .ok), body: .init(json: []))
        promise.succeed(response)
        return promise.futureResult
    })
    var root: String
}

class UserController: RequestController, MappingProtocol {
    
    let mapping: String = "/user"
    
    @RequestMapping("/info", { request, channel, token in
        let promise = channel.eventLoop.makePromise(of: MessageResponse.self)
        let response = MessageResponse(head: .init(version: .init(major: 2, minor: 0), status: .ok), body: .init(json: [
            "name": "tom",
            "age": 20,
        ]))
        promise.succeed(response)
        return promise.futureResult
    })
    var info: String
    
    @RequestMapping("/update", method: [.POST], { request, channel, token in
        let promise = channel.eventLoop.makePromise(of: MessageResponse.self)
        let response = MessageResponse(head: .init(version: .init(major: 2, minor: 0), status: .ok), body: .init(json: []))
        promise.succeed(response)
        return promise.futureResult
    })
    var update: String
}

```
