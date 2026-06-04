// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Tuck",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Tuck", targets: ["Tuck"])
    ],
    targets: [
        .executableTarget(
            name: "Tuck",
            path: "Sources/Tuck"
        ),
        .testTarget(
            name: "TuckTests",
            dependencies: ["Tuck"],
            path: "Tests/TuckTests"
        )
    ]
)
