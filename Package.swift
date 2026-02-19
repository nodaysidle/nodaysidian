// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "NodaysIdle",
    platforms: [
        .macOS(.v15),
    ],
    targets: [
        .executableTarget(
            name: "NodaysIdle",
            path: "Sources/NodaysIdle",
            resources: [
                .process("Resources"),
            ]
        )
    ]
)
