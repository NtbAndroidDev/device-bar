// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DeviceBar",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "DeviceBar",
            targets: ["DeviceBar"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "DeviceBar",
            dependencies: [],
            path: "Sources/DeviceBar"
        )
    ]
)
