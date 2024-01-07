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
        .package(url: "https://github.com/nathanborror/swift-sharedkit", branch: "main"),
        .package(url: "https://github.com/nathanborror/swift-genkit", branch: "main"),
    ],
    targets: [
        .target(name: "HeatKit", dependencies: [
            .product(name: "SharedKit", package: "swift-sharedkit"),
            .product(name: "GenKit", package: "swift-genkit"),
        ]),
        .testTarget(name: "HeatKitTests", dependencies: ["HeatKit"]),
    ]
)
