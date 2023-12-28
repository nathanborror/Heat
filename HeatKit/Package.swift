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
        .package(url: "https://github.com/nathanborror/SharedKit", branch: "main"),
        .package(url: "https://github.com/nathanborror/GenKit", branch: "main"),
    ],
    targets: [
        .target(name: "HeatKit", dependencies: [
            .product(name: "SharedKit", package: "SharedKit"),
            .product(name: "GenKit", package: "GenKit"),
        ]),
        .testTarget(name: "HeatKitTests", dependencies: ["HeatKit"]),
    ]
)
