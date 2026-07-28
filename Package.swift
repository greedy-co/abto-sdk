// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "AbtoApp",
    platforms: [.iOS(.v14), .macOS(.v12)],
    products: [
        .library(name: "AbtoApp", targets: ["AbtoApp"])
    ],
    targets: [
        .target(
            name: "AbtoApp",
            path: "packages/mobile/swift/Sources/AbtoApp"
        ),
        .executableTarget(
            name: "abto-sdk-checks",
            dependencies: ["AbtoApp"],
            path: "packages/mobile/swift/Sources/abto-sdk-checks"
        ),
    ]
)
