// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "quiltwright",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "QuiltwrightUI", targets: ["QuiltwrightUI"]),
        .executable(name: "QuiltwrightMac", targets: ["QuiltwrightMac"]),
        .executable(name: "QuiltwrightChecks", targets: ["QuiltwrightChecks"]),
    ],
    targets: [
        .target(name: "QuiltwrightUI"),
        .executableTarget(name: "QuiltwrightMac", dependencies: ["QuiltwrightUI"]),
        .executableTarget(
            name: "QuiltwrightChecks",
            dependencies: ["QuiltwrightUI"],
            path: "Tests/QuiltwrightChecks"
        ),
    ]
)
