// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "DeviceSim",
    platforms: [
        .macOS(.v12)
    ],
    dependencies: [
        .package(url: "https://github.com/krzysztofzablocki/Inject.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "DeviceSim",
            dependencies: ["Inject"]
        )
    ]
) 