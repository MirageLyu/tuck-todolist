// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Tuck",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Tuck", targets: ["Tuck"]),
        .library(name: "TuckUITestFramework", targets: ["TuckUITestFramework"]),
    ],
    targets: [
        .executableTarget(
            name: "Tuck",
            path: "Sources/Tuck"
        ),
        .target(
            name: "TuckUITestFramework",
            path: "Sources/TuckUITestFramework"
        ),
        .testTarget(
            name: "TuckTests",
            dependencies: ["Tuck"],
            path: "Tests/TuckTests"
        ),
        .testTarget(
            name: "TuckComponentTests",
            dependencies: ["Tuck", "TuckUITestFramework"],
            path: "Tests/TuckComponentTests"
        ),
        .testTarget(
            name: "TuckE2ETests",
            dependencies: ["TuckUITestFramework"],
            path: "Tests/TuckE2ETests"
        ),
    ]
)
