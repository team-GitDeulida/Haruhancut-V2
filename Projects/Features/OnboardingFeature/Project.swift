import ProjectDescription

let project = Project(
    name: "Onboarding",
    targets: [
    
        // MARK: - Feature Framework
        .target(
            name: "OnboardingFeature",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.indextrown.Haruhancut.onboardingfeature",
            deploymentTargets: .iOS("17.0"),
            sources: ["Sources/**"],
            resources: [],
            dependencies: [
                .target(name: "OnboardingFeatureInterface"),
                .project(target: "DSKit", path: "../../Shared/DSKit"),
                .project(target: "ThirdPartyLibs", path: "../../Shared/ThirdPartyLibs")
            ]
        ),
        
        // MARK: - FeatureInterface Framework
        .target(
            name: "OnboardingFeatureInterface",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.indextrown.Haruhancut.onboardingfeature.interface",
            deploymentTargets: .iOS("17.0"),
            sources: ["Interface/Sources/**"],
            resources: [],
            dependencies: [
                .project(target: "DSKit", path: "../../Shared/DSKit"),
                .project(target: "Domain", path: "../../Domain")
            ]
        ),
        
        // MARK: - FeatureDemo App
        .target(
            name: "OnboardingFeatureDemo",
            destinations: .iOS,
            product: .app,
            bundleId: "com.indextrown.Haruhancut.onboardingfeature.demo",
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
                .target(name: "OnboardingFeature"),
                // .target(name: "OnboardingFeatureTesting")
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
        // .target(
        //     name: "OnboardingTests",
        //     destinations: .iOS,
        //     product: .unitTests,
        //     bundleId: "com.indextrown.Haruhancut.onboardingfeature.tests",
        //     deploymentTargets: .iOS("17.0"),
        //     sources: ["Tests/Sources/**"],
        //     resources: [],
        //     dependencies: [
        //         .target(name: "OnboardingFeature"),
        //         .target(name: "OnboardingFeatureTesting")
        //     ]
        // ),

        // MARK: - Feature Testing
        // .target(
        //     name: "OnboardingFeatureTesting",
        //     destinations: .iOS,
        //     product: .framework,
        //     bundleId: "com.indextrown.Haruhancut.onboardingfeature.testing",
        //     deploymentTargets: .iOS("17.0"),
        //     sources: ["Testing/Sources/**"],
        //     resources: [],
        //     dependencies: [
        //         .target(name: "OnboardingFeatureInterface")
        //     ]
        // ),
    ]
)

