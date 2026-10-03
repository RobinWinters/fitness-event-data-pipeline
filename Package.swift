// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FitnessEventDataPipeline",
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [
        .library(name: "FitnessEventDataPipeline", targets: ["FitnessEventDataPipeline"]),
        .executable(name: "normalize-events", targets: ["NormalizeEvents"]),
    ],
    targets: [
        .target(name: "FitnessEventDataPipeline"),
        .executableTarget(name: "NormalizeEvents", dependencies: ["FitnessEventDataPipeline"]),
        .testTarget(name: "FitnessEventDataPipelineTests", dependencies: ["FitnessEventDataPipeline"]),
    ]
)
