// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HeatKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .watchOS(.v10),
        .tvOS(.v17)
    ],
    products: [
        .library(name: "HeatKit", targets: ["HeatKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/nathanborror/OllamaKit", branch: "main"),
    ],
    targets: [
        .target(name: "HeatKit", dependencies: [
            .product(name: "OllamaKit", package: "OllamaKit"),
        ]),
        .testTarget(name: "HeatKitTests", dependencies: ["HeatKit"]),
    ]
)
