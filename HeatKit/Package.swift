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
        .package(url: "git@github.com:nathanborror/swift-shared-kit", branch: "main"),
        .package(url: "git@github.com:nathanborror/swift-gen-kit", branch: "main"),
        .package(url: "git@github.com:cezheng/Fuzi", branch: "master"),
    ],
    targets: [
        .target(
            name: "HeatKit",
            dependencies: [
                .product(name: "SharedKit", package: "swift-shared-kit"),
                .product(name: "GenKit", package: "swift-gen-kit"),
                .product(name: "Fuzi", package: "Fuzi"),
            ]
        ),
        .testTarget(name: "HeatKitTests", dependencies: ["HeatKit"]),
    ]
)
