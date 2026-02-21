import ProjectDescription

let project = Project(
    name: "Profile",
    targets: [
    
        // MARK: - Feature Framework
        .target(
            name: "ProfileFeature",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.indextrown.Haruhancut.profilefeature",
            deploymentTargets: .iOS("17.0"),
            sources: ["Sources/**"],
            resources: [],
            dependencies: [
                .target(name: "ProfileFeatureInterface"),
                .project(target: "DSKit", path: "../../Shared/DSKit"),
                .project(target: "ThirdPartyLibs", path: "../../Shared/ThirdPartyLibs")
            ]
        ),
        
        // MARK: - FeatureInterface Framework
        .target(
            name: "ProfileFeatureInterface",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.indextrown.Haruhancut.profilefeature.interface",
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
            name: "ProfileFeatureDemo",
            destinations: .iOS,
            product: .app,
            bundleId: "com.indextrown.Haruhancut.profilefeature.demo",
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
                .target(name: "ProfileFeature"),
                // .target(name: "ProfileFeatureTesting")
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
        //     name: "ProfileTests",
        //     destinations: .iOS,
        //     product: .unitTests,
        //     bundleId: "com.indextrown.Haruhancut.profilefeature.tests",
        //     deploymentTargets: .iOS("17.0"),
        //     sources: ["Tests/Sources/**"],
        //     resources: [],
        //     dependencies: [
        //         .target(name: "ProfileFeature"),
        //         .target(name: "ProfileFeatureTesting")
        //     ]
        // ),

        // MARK: - Feature Testing
        // .target(
        //     name: "ProfileFeatureTesting",
        //     destinations: .iOS,
        //     product: .framework,
        //     bundleId: "com.indextrown.Haruhancut.profilefeature.testing",
        //     deploymentTargets: .iOS("17.0"),
        //     sources: ["Testing/Sources/**"],
        //     resources: [],
        //     dependencies: [
        //         .target(name: "ProfileFeatureInterface")
        //     ]
        // ),
    ]
)

