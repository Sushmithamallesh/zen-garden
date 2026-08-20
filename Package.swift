// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ZenGarden",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "ZenGarden", targets: ["ZenGarden"])
    ],
    targets: [
        .executableTarget(
            name: "ZenGarden",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
