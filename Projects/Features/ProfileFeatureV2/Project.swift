import ProjectDescription

let project = Project(
    name: "ProfileV2",
    targets: [
        .target(
            name: "ProfileFeatureV2",
            destinations: .iOS,
            product: .staticFramework,
            bundleId:
                "com.indextrown.Haruhancut.profilefeaturev2",
            deploymentTargets: .iOS("17.0"),
            sources: ["Sources/**"],
            resources: [],
            dependencies: [
                .target(
                    name:
                        "ProfileFeatureV2Interface"
                ),
                .project(
                    target:
                        "CollectionViewAdapter",
                    path:
                        "../../Shared/CollectionViewAdapter"
                ),
                .project(
                    target: "DSKit",
                    path: "../../Shared/DSKit"
                ),
                .project(
                    target: "Core",
                    path: "../../Core"
                ),
                .project(
                    target: "Domain",
                    path: "../../Domain"
                ),
                .project(
                    target: "ThirdPartyLibs",
                    path:
                        "../../Shared/ThirdPartyLibs"
                ),
            ]
        ),
        .target(
            name: "ProfileFeatureV2Interface",
            destinations: .iOS,
            product: .framework,
            bundleId:
                "com.indextrown.Haruhancut.profilefeaturev2.interface",
            deploymentTargets: .iOS("17.0"),
            sources: ["Interface/Sources/**"],
            resources: [],
            dependencies: [
                .project(
                    target: "Core",
                    path: "../../Core"
                ),
                .project(
                    target: "Domain",
                    path: "../../Domain"
                ),
            ]
        ),
        .target(
            name: "ProfileFeatureV2Demo",
            destinations: .iOS,
            product: .app,
            bundleId:
                "com.indextrown.Haruhancut.profilefeaturev2.demo",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [:],
                    "UIUserInterfaceStyle": "Dark",
                    "UISupportedInterfaceOrientations": [
                        "UIInterfaceOrientationPortrait",
                    ],
                    "UIApplicationSceneManifest": [
                        "UIApplicationSupportsMultipleScenes":
                            true,
                        "UISceneConfigurations": [
                            "UIWindowSceneSessionRoleApplication": [
                                [
                                    "UISceneConfigurationName":
                                        "Default Configuration",
                                    "UISceneDelegateClassName":
                                        "$(PRODUCT_MODULE_NAME).SceneDelegate",
                                ],
                            ],
                        ],
                    ],
                ]
            ),
            sources: ["Demo/Sources/**"],
            resources: [],
            dependencies: [
                .target(
                    name: "ProfileFeatureV2"
                ),
                .target(
                    name:
                        "ProfileFeatureV2Interface"
                ),
                .project(
                    target: "Core",
                    path: "../../Core"
                ),
                .project(
                    target: "Domain",
                    path: "../../Domain"
                ),
                .project(
                    target: "ThirdPartyLibs",
                    path:
                        "../../Shared/ThirdPartyLibs"
                ),
            ],
            settings: .settings(
                configurations: [
                    .debug(
                        name: "Debug",
                        xcconfig:
                            "../../Shared/Configs/Shared.xcconfig"
                    ),
                    .release(
                        name: "Release",
                        xcconfig:
                            "../../Shared/Configs/Shared.xcconfig"
                    ),
                ]
            )
        ),
        .target(
            name: "ProfileFeatureV2Tests",
            destinations: .iOS,
            product: .unitTests,
            bundleId:
                "com.indextrown.Haruhancut.profilefeaturev2.tests",
            deploymentTargets: .iOS("17.0"),
            sources: ["Tests/Sources/**"],
            resources: [],
            dependencies: [
                .target(
                    name: "ProfileFeatureV2"
                ),
                .project(
                    target: "Domain",
                    path: "../../Domain"
                ),
            ]
        ),
    ],
    schemes: [
        .scheme(
            name: "ProfileFeatureV2",
            shared: true,
            buildAction: .buildAction(
                targets: ["ProfileFeatureV2"]
            ),
            testAction: .targets(
                ["ProfileFeatureV2Tests"],
                configuration: "Debug"
            )
        ),
        .scheme(
            name: "ProfileFeatureV2Demo",
            shared: true,
            buildAction: .buildAction(
                targets: [
                    "ProfileFeatureV2Demo",
                ]
            ),
            runAction: .runAction(
                configuration: "Debug"
            )
        ),
    ]
)
