// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "Dr. Hallervorden",
    products: [
        .executable(name: "Dr. Hallervorden", targets: ["RogueKit"]),
        .library(name: "RogueKit", targets: ["RogueKit"]),
    ],
    dependencies: [
         .package(url: "https://github.com/irskep/BearLibTerminal-Swift.git", from: "1.0.6"),
         .package(url: "https://github.com/1024jp/GzipSwift.git", from: "4.0.4"),
    ],
    targets: [
        .target(
            name: "RogueKit",
            dependencies: ["BearLibTerminal", "Gzip"]),

    ]
)
