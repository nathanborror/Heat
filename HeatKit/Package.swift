// swift-tools-version: 6.0
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
        .package(url: "https://github.com/nathanborror/swift-shared-kit", from: "0.1.0"),
        .package(url: "https://github.com/nathanborror/swift-gen-kit", branch: "main"),
        .package(url: "https://github.com/cezheng/Fuzi", branch: "master"),
        .package(url: "https://github.com/jkrukowski/SQLiteVec", branch: "main"),
    ],
    targets: [
        .target(
            name: "HeatKit",
            dependencies: [
                .product(name: "SharedKit", package: "swift-shared-kit"),
                .product(name: "GenKit", package: "swift-gen-kit"),
                .product(name: "Fuzi", package: "Fuzi"),
                .product(name: "SQLiteVec", package: "SQLiteVec"),
            ]
        ),
    ]
)
