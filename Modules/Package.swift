// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Modules",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .library(
            name: "Domain",
            targets: ["Domain"]),
        .library(
            name: "Samples",
            targets: ["Samples"]),
        .library(
            name: "Presentation",
            targets: ["Presentation"]),
        .library(
            name: "Producer",
            targets: ["Producer"]),
    ],
    targets: [
        .target(
            name: "Domain"),
        .target(
            name: "Samples",
            dependencies: ["Domain"],
            resources: [.process("Store/Resources"),]),
        .target(
            name: "Presentation",
            dependencies: ["Domain", "Samples", "Producer"]),
        .target(
            name: "Producer",
            dependencies: ["Domain", "Samples"]),
        .testTarget(
            name: "SamplesTests",
            dependencies: ["Domain", "Samples"]),
        .testTarget(
            name: "PresentationTests",
            dependencies: ["Domain", "Samples", "Presentation"]),
        .testTarget(
            name: "ProducerTests",
            dependencies: ["Domain", "Samples", "Producer"]),
    ]
)
