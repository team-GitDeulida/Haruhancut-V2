import ProjectDescription

let project = Project(
    name: "Auth",
    targets: [
    
        // MARK: - Feature Framework
        .target(
            name: "AuthFeature",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "com.indextrown.Haruhancut.authfeature",
            deploymentTargets: .iOS("17.0"),
            sources: ["Sources/**"],
            resources: [],
            dependencies: [
                .target(name: "AuthFeatureInterface"),
                .project(target: "DSKit", path: "../../Shared/DSKit"),
                .project(target: "ThirdPartyLibs", path: "../../Shared/ThirdPartyLibs")
            ]
        ),
        
        // MARK: - FeatureInterface Framework
        .target(
            name: "AuthFeatureInterface",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.indextrown.Haruhancut.authfeature.interface",
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
            name: "AuthFeatureDemo",
            destinations: .iOS,
            product: .app,
            bundleId: "com.indextrown.Haruhancut.authfeature.demo",
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
                .target(name: "AuthFeature"),
                .project(target: "Domain", path: "../../Domain")
                // .target(name: "AuthFeatureTesting")
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
        //     name: "AuthTests",
        //     destinations: .iOS,
        //     product: .unitTests,
        //     bundleId: "com.indextrown.Haruhancut.authfeature.tests",
        //     deploymentTargets: .iOS("17.0"),
        //     sources: ["Tests/Sources/**"],
        //     resources: [],
        //     dependencies: [
        //         .target(name: "AuthFeature"),
        //         .target(name: "AuthFeatureTesting")
        //     ]
        // ),

        // MARK: - Feature Testing
        // .target(
        //     name: "AuthFeatureTesting",
        //     destinations: .iOS,
        //     product: .framework,
        //     bundleId: "com.indextrown.Haruhancut.authfeature.testing",
        //     deploymentTargets: .iOS("17.0"),
        //     sources: ["Testing/Sources/**"],
        //     resources: [],
        //     dependencies: [
        //         .target(name: "AuthFeatureInterface")
        //     ]
        // ),
    ]
)

