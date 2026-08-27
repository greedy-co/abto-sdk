// swift-tools-version:5.9
import PackageDescription

// Keep tests in the framework-free checks executable (`swift run abto-sdk-checks`)
// so verification also runs in Command Line Tools environments without XCTest or swift-testing.
let package = Package(
    name: "AbtoApp",
    platforms: [.iOS(.v14), .macOS(.v12)],
    products: [
        .library(name: "AbtoApp", targets: ["AbtoApp"])
    ],
    targets: [
        .target(name: "AbtoApp"),
        .executableTarget(name: "abto-sdk-checks", dependencies: ["AbtoApp"]),
    ]
)
