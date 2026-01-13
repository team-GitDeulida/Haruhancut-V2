import ProjectDescription

let project = Project(
    name: "RxLab",
    targets: [
    
        // MARK: - Feature Framework
        .target(
            name: "RxLab",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.indextrown.Haruhancut.rxlab",
            deploymentTargets: .iOS("17.0"),
            sources: ["Sources/**"],
            resources: [],
            dependencies: [
                .target(name: "RxLabInterface")
            ]
        ),
        
        // MARK: - FeatureInterface Framework
        .target(
            name: "RxLabInterface",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.indextrown.Haruhancut.rxlab.interface",
            deploymentTargets: .iOS("17.0"),
            sources: ["Interface/Sources/**"],
            resources: [],
            dependencies: []
        ),
        
        // MARK: - FeatureDemo App
        .target(
            name: "RxLabDemo",
            destinations: .iOS,
            product: .app,
            bundleId: "com.indextrown.Haruhancut.rxlab.demo",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: [
                // Storyboard 미사용
                "UILaunchScreen": [:],

                 // Scene 설정
                "UIApplicationSceneManifest": [
                    "UIApplicationSupportsMultipleScenes": true,
                    "UISceneConfigurations": [
                        "UIWindowSceneSessionRoleApplication": [
                            [
                                "UISceneConfigurationName": "Default Configuration",
                                "UISceneDelegateClassName": "$(PRODUCT_MODULE_NAME).SceneDelegate"
                            ]
                        ]
                    ]
                ],
            ]),
            sources: ["Demo/**"],
            resources: [],
            dependencies: [
                .target(name: "RxLab"),
                .target(name: "RxLabTesting")
            ],
            settings: .settings(
                configurations: [
                    .debug(
                        name: "Debug",
                        xcconfig: "../../Shared/Configs/Shared.xcconfig"
                    ),
                    .release(
                        name: "Release",
                        xcconfig: "../../Shared/Configs/Shared.xcconfig"
                    )
                ]
            )
        ),

        // MARK: - Feature Tests
        .target(
            name: "RxLabTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.indextrown.Haruhancut.rxlab.tests",
            deploymentTargets: .iOS("17.0"),
            sources: ["Tests/Sources/**"],
            resources: [],
            dependencies: [
                .target(name: "RxLab"),
                .target(name: "RxLabTesting")
            ]
        ),

        // MARK: - Feature Testing
        .target(
            name: "RxLabTesting",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.indextrown.Haruhancut.rxlab.testing",
            deploymentTargets: .iOS("17.0"),
            sources: ["Testing/Sources/**"],
            resources: [],
            dependencies: [
                .target(name: "RxLabInterface")
            ]
        ),
    ]
)

