// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "XcodeTargets",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
        .package(url: "https://github.com/tuist/XcodeProj.git", .upToNextMajor(from: "9.5.0")),
        .package(url: "https://github.com/tuist/Path.git", .upToNextMajor(from: "0.3.8")),
        .package(url: "https://github.com/SimplyDanny/SwiftLintPlugins.git", .upToNextMajor(from: "0.62.1"))
    ],
    targets: [
        .executableTarget(
            name: "XcodeTargets",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "XcodeProj", package: "XcodeProj"),
                .product(name: "Path", package: "Path")
            ],
            plugins: [
                .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")
            ]
        ),
        .testTarget(
            name: "XcodeTargetsTests",
            dependencies: [
                "XcodeTargets",
                .product(name: "XcodeProj", package: "XcodeProj")
            ],
            resources: [.copy("Example")]
        )
    ]
)
