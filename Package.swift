// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Retab",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Retab",
            path: "Sources/Retab"
        ),
        .testTarget(
            name: "RetabTests",
            dependencies: ["Retab"],
            path: "Tests/RetabTests"
        ),
    ]
)
