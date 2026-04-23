import ProjectDescription

let project = Project(
    name: "Sotto",
    settings: .settings(
        base: [
            "SWIFT_VERSION": "6.0",
            "MACOSX_DEPLOYMENT_TARGET": "14.0",
            "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
        ]
    ),
    targets: [
        .target(
            name: "Sotto",
            destinations: [.iPhone, .iPad, .mac],
            product: .app,
            bundleId: "com.sotto.app",
            deploymentTargets: .multiplatform(iOS: "17.0", macOS: "14.0"),
            infoPlist: .extendingDefault(
                with: [
                    "LSApplicationCategoryType": "public.app-category.finance",
                    "UILaunchScreen": [:],
                ]
            ),
            sources: [
                .glob("Sotto/**", excluding: ["Sotto/**/.DS_Store"]),
            ],
            resources: ["Resources/**"],
            entitlements: "Sotto.entitlements",
            dependencies: [],
            settings: .settings(
                base: [
                    "PRODUCT_NAME": "Sotto",
                    "SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD": "NO",
                ]
            )
        ),
        .target(
            name: "SottoTests",
            destinations: .macOS,
            product: .unitTests,
            bundleId: "com.sotto.app.tests",
            deploymentTargets: .macOS("14.0"),
            infoPlist: .extendingDefault(with: [:]),
            sources: ["SottoTests/**"],
            dependencies: [
                .target(name: "Sotto"),
            ]
        ),
    ],
    schemes: [
        .scheme(
            name: "Sotto",
            shared: true,
            buildAction: .buildAction(targets: ["Sotto"]),
            runAction: .runAction(configuration: .debug),
            archiveAction: .archiveAction(configuration: .release)
        ),
        .scheme(
            name: "SottoTests",
            shared: true,
            buildAction: .buildAction(targets: ["SottoTests"]),
            testAction: .targets(
                ["SottoTests"],
                configuration: .debug
            )
        ),
    ]
)
