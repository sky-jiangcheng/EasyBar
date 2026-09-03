// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "StatusBar Pro",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "StatusBar Pro", targets: ["StatusBar Pro"])
    ],
    targets: [
        .executableTarget(
            name: "StatusBar Pro",
            path: "Sources/StatusBar Pro",
            exclude: [
                "Resources"
            ]
        )
    ]
)
