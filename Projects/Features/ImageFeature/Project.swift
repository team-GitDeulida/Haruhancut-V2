import ProjectDescription

let project = Project(
    name: "Image",
    targets: [
    
        // MARK: - Feature Framework
        .target(
            name: "ImageFeature",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.indextrown.Haruhancut.imagefeature",
            deploymentTargets: .iOS("17.0"),
            sources: ["Sources/**"],
            resources: [],
            dependencies: [
                .target(name: "ImageFeatureInterface")
            ]
        ),
        
        // MARK: - FeatureInterface Framework
        .target(
            name: "ImageFeatureInterface",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.indextrown.Haruhancut.imagefeature.interface",
            deploymentTargets: .iOS("17.0"),
            sources: ["Interface/Sources/**"],
            resources: [],
            dependencies: []
        ),
        
        // MARK: - FeatureDemo App
        .target(
            name: "ImageFeatureDemo",
            destinations: .iOS,
            product: .app,
            bundleId: "com.indextrown.Haruhancut.imagefeature.demo",
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
                .target(name: "ImageFeature"),
                .target(name: "ImageFeatureTesting")
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
            name: "ImageTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.indextrown.Haruhancut.imagefeature.tests",
            deploymentTargets: .iOS("17.0"),
            sources: ["Tests/Sources/**"],
            resources: [],
            dependencies: [
                .target(name: "ImageFeature"),
                .target(name: "ImageFeatureTesting")
            ]
        ),

        // MARK: - Feature Testing
        .target(
            name: "ImageFeatureTesting",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.indextrown.Haruhancut.imagefeature.testing",
            deploymentTargets: .iOS("17.0"),
            sources: ["Testing/Sources/**"],
            resources: [],
            dependencies: [
                .target(name: "ImageFeatureInterface")
            ]
        ),
    ]
)

