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
            name: "Persistence",
            targets: ["Persistence"]),
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
            name: "Persistence",
            dependencies: ["Domain"],
            resources: [.process("Resources"),]),
        .target(
            name: "Presentation",
            dependencies: ["Domain"]),
        .target(
            name: "Producer",
            dependencies: ["Domain"]),
        .testTarget(
            name: "PersistenceTests",
            dependencies: ["Domain", "Persistence"]),
        .testTarget(
            name: "PresentationTests",
            dependencies: ["Domain", "Presentation"]),
        .testTarget(
            name: "ProducerTests",
            dependencies: ["Domain", "Producer"]),
    ]
)
