// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CBB",
    platforms: [.macOS("26.0")],
    products: [
        .library(name: "CBBCore", targets: ["CBBCore"]),
        .library(name: "CBBUI", targets: ["CBBUI"]),
        .executable(name: "cbb-render", targets: ["cbb-render"]),
    ],
    targets: [
        .target(name: "CBBCore"),
        .target(name: "CBBUI", dependencies: ["CBBCore"]),
        .executableTarget(name: "cbb-render", dependencies: ["CBBCore", "CBBUI"]),
        .testTarget(
            name: "CBBCoreTests",
            dependencies: ["CBBCore"],
            resources: [.copy("Fixtures")]
        ),
    ]
)
