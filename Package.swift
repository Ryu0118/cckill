// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "cckill",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "cckill", targets: ["cckill"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.6.2"),
        .package(url: "https://github.com/swiftlang/swift-subprocess.git", from: "0.1.0"),
    ],
    targets: [
        .executableTarget(
            name: "cckill",
            dependencies: ["CCKillCLI"]
        ),
        .target(
            name: "CCKillCLI",
            dependencies: [
                "CCKillKit",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .target(
            name: "CCKillKit",
            dependencies: [
                .product(name: "Subprocess", package: "swift-subprocess"),
            ]
        ),
    ]
)
