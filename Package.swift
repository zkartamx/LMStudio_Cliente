// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MiMoApp",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .executable(name: "MiMoApp", targets: ["MiMoApp"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-testing", from: "0.5.0")
    ],
    targets: [
        .executableTarget(
            name: "MiMoApp",
            path: "MiMoApp",
            resources: [
                .process("Assets.xcassets")
            ]
        ),
        .testTarget(
            name: "MiMoAppTests",
            dependencies: [
                "MiMoApp",
                .product(name: "Testing", package: "swift-testing")
            ],
            path: "MiMoAppTests"
        ),
        .testTarget(
            name: "MiMoAppUITests",
            dependencies: ["MiMoApp"],
            path: "MiMoAppUITests"
        )
    ]
)
