// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MobileDevBar",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "MobileDevBar",
            targets: ["MobileDevBar"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "MobileDevBar",
            dependencies: [],
            path: "Sources/MobileDevBar"
        )
    ]
)
