// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MindBender2",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "Shared", targets: ["Shared"]),
        .library(name: "App", targets: ["App"]),
        .executable(name: "MindBenderProxy", targets: ["MindBenderProxy"])
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.92.0")
    ],
    targets: [
        .target(
            name: "Shared",
            path: "Sources/Shared"
        ),
        .target(
            name: "App",
            dependencies: ["Shared"],
            path: "Sources/App"
        ),
        .executableTarget(
            name: "MindBenderProxy",
            dependencies: [
                "Shared",
                .product(name: "Vapor", package: "vapor")
            ],
            path: "Sources/MindBenderProxy"
        ),
        .testTarget(
            name: "SharedTests",
            dependencies: ["Shared"],
            path: "Tests/SharedTests"
        ),
        .testTarget(
            name: "MindBenderProxyTests",
            dependencies: [
                "MindBenderProxy",
                .product(name: "XCTVapor", package: "vapor")
            ],
            path: "Tests/MindBenderProxyTests"
        )
    ]
)
