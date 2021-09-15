// swift-tools-version:5.2
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
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.32.2"),
        .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "2.15.0"),
        .package(url: "https://github.com/apple/swift-nio-http2.git", from: "1.18.2"),
    ],
    targets: [
        
        // library
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

        // executable
        .target(
            name: "SHTTPD",
            dependencies: ["SHTTP"]
        ),
    ]
)
