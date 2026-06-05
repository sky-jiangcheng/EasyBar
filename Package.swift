// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacStatusApp",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "MacStatusApp", targets: ["MacStatusApp"])
    ],
    targets: [
        .executableTarget(
            name: "MacStatusApp",
            path: "Sources/MacStatusApp",
            exclude: [
                "Resources"
            ]
        )
    ]
)
