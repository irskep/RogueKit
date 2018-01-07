// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RogueKit",
    products: [
        .executable(name: "RogueKit Demo", targets: ["RogueKit"]),
        .library(name: "RogueKit", targets: ["RogueKit"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
         .package(url: "https://github.com/irskep/BearLibTerminal-Swift.git", from: "1.0.1"),
    ],
    targets: [
        .target(
            name: "RogueKit",
            dependencies: ["BearLibTerminal"]),

    ]
)
