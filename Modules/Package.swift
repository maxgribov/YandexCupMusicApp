// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Modules",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .library(
            name: "Samples",
            targets: ["Samples"]),
        .library(
            name: "Presentation",
            targets: ["Presentation"]),
    ],
    targets: [
        .target(
            name: "Samples",
            resources: [.process("Store/Resources"),]),
        .target(
            name: "Presentation",
            dependencies: ["Samples"]),
        .testTarget(
            name: "SamplesTests",
            dependencies: ["Samples"]),
        .testTarget(
            name: "PresentationTests",
            dependencies: ["Samples", "Presentation"]),
    ]
)
