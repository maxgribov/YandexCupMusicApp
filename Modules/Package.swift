// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Modules",
    platforms: [.iOS(.v13), .macOS(.v13)],
    products: [
        .library(
            name: "Samples",
            targets: ["Samples"]),
    ],
    targets: [
        .target(
            name: "Samples",
            resources: [.process("Store/Resources"),]),
        .testTarget(
            name: "SamplesTests",
            dependencies: ["Samples"]),
    ]
)
