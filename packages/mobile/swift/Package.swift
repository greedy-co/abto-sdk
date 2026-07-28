// swift-tools-version:5.9
import PackageDescription

// XCTest/swift-testing 이 없는 Command Line Tools 환경에서도 검증이 돌도록
// 테스트는 프레임워크 의존 없는 checks 실행 파일(swift run abto-sdk-checks)로 둔다.
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
