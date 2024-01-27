// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "snake-http",
    products: [
        .library(
            name: "SHTTP",
            targets: ["SHTTP"]
        ),
        .executable(
            name: "SHTTPD",
            targets: ["SHTTPD"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.63.0"),
        .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "2.26.0"),
        .package(url: "https://github.com/apple/swift-nio-http2.git", from: "1.30.0"),
    ],
    targets: [
        
        .target(
            name: "SHTTP",
            dependencies: [
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOSSL", package: "swift-nio-ssl"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
                .product(name: "NIOHTTP2", package: "swift-nio-http2"),
                .product(name: "NIOFoundationCompat", package: "swift-nio"),
            ]
        ),
        
        .executableTarget(
            name: "SHTTPD",
            dependencies: ["SHTTP"]
        ),
        
        .testTarget(
            name: "SHTTPTest",
            dependencies: [
                "SHTTP"
            ],
            path: "Tests"
        )
    ]
)
