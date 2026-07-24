// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "NagaReader",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "NagaReaderCore", targets: ["NagaReaderCore"]),
        .executable(name: "NagaReader", targets: ["NagaReader"])
    ],
    targets: [
        .target(name: "NagaReaderCore"),
        .executableTarget(
            name: "NagaReader",
            dependencies: ["NagaReaderCore"]
        ),
        .testTarget(
            name: "NagaReaderCoreTests",
            dependencies: ["NagaReaderCore"]
        )
    ]
)
