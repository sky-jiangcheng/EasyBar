// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "EasyBar",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "EasyBar", targets: ["EasyBar"])
    ],
    targets: [
        .executableTarget(
            name: "EasyBar",
            path: "Sources/EasyBar",
            exclude: [
                "Resources"
            ]
        )
    ]
)
