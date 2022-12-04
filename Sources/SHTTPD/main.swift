//
//  main.swift
//  snake-httpd
//
//  Created by panghu on 7/5/20.
//

import SHTTP

let bootstrap = Bootstrap(
    configuration: .init(host: "127.0.0.1", port: 8889),
    eventLoopGroup: .init(numberOfThreads: System.coreCount)
)

try bootstrap.start().wait()
bootstrap.printAddress()
try bootstrap.onClose.wait()
