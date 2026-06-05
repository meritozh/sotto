// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Sotto",
    defaultLocalization: "en",
    platforms: [
        .iOS("26.0"),
        .macOS("26.0"),
    ],
    products: [
        .library(
            name: "SottoKit",
            targets: ["SottoKit"]
        ),
    ],
    targets: [
        .target(
            name: "SottoKit",
            path: "Sotto",
            exclude: [
                "App",
            ]
        ),
        .testTarget(
            name: "SottoKitTests",
            dependencies: ["SottoKit"],
            path: "SottoTests"
        ),
    ]
)
