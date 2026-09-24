// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "StatusBar",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "StatusBar", targets: ["StatusBar"])
    ],
    targets: [
        .executableTarget(
            name: "StatusBar",
            path: "Sources/StatusBar",
            exclude: [
                "Resources"
            ]
        ),
        .testTarget(
            name: "StatusBarTests",
            dependencies: ["StatusBar"],
            path: "Tests/StatusBarTests"
        )
    ]
)
