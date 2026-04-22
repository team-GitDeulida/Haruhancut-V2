import ProjectDescription

let project = Project(
    name: "Member",
    targets: [
    
        // MARK: - Feature Framework
        .target(
            name: "MemberFeature",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "com.indextrown.Haruhancut.memberfeature",
            deploymentTargets: .iOS("17.0"),
            sources: ["Sources/**"],
            resources: [],
            dependencies: [
                .target(name: "MemberFeatureInterface"),
                .project(target: "DSKit", path: "../../Shared/DSKit"),
                .project(target: "ThirdPartyLibs", path: "../../Shared/ThirdPartyLibs")
            ]
        ),
        
        // MARK: - FeatureInterface Framework
        .target(
            name: "MemberFeatureInterface",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "com.indextrown.Haruhancut.memberfeature.interface",
            deploymentTargets: .iOS("17.0"),
            sources: ["Interface/Sources/**"],
            resources: [],
            dependencies: [
                .project(target: "Domain", path: "../../Domain")
            ]
        ),
        
        // MARK: - FeatureDemo App
        .target(
            name: "MemberFeatureDemo",
            destinations: .iOS,
            product: .app,
            bundleId: "com.indextrown.Haruhancut.memberfeature.demo",
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
                .target(name: "MemberFeature"),
                // .target(name: "MemberFeatureTesting")
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
        //     name: "MemberTests",
        //     destinations: .iOS,
        //     product: .unitTests,
        //     bundleId: "com.indextrown.Haruhancut.memberfeature.tests",
        //     deploymentTargets: .iOS("17.0"),
        //     sources: ["Tests/Sources/**"],
        //     resources: [],
        //     dependencies: [
        //         .target(name: "MemberFeature"),
        //         .target(name: "MemberFeatureTesting")
        //     ]
        // ),

        // MARK: - Feature Testing
        // .target(
        //     name: "MemberFeatureTesting",
        //     destinations: .iOS,
        //     product: .framework,
        //     bundleId: "com.indextrown.Haruhancut.memberfeature.testing",
        //     deploymentTargets: .iOS("17.0"),
        //     sources: ["Testing/Sources/**"],
        //     resources: [],
        //     dependencies: [
        //         .target(name: "MemberFeatureInterface")
        //     ]
        // ),
    ]
)
