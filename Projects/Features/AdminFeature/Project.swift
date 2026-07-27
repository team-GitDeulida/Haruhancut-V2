import ProjectDescription

let project = Project(
    name: "Admin",
    targets: [
        .target(
            name: "AdminFeature",
            destinations: .iOS,
            product: .staticFramework,
            bundleId:
                "com.indextrown.Haruhancut.adminfeature",
            deploymentTargets: .iOS("17.0"),
            sources: ["Sources/**"],
            resources: [],
            dependencies: [
                .target(
                    name:
                        "AdminFeatureInterface"
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
            name:
                "AdminFeatureInterface",
            destinations: .iOS,
            product: .framework,
            bundleId:
                "com.indextrown.Haruhancut.adminfeature.interface",
            deploymentTargets: .iOS("17.0"),
            sources:
                ["Interface/Sources/**"],
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
            name: "AdminFeatureDemo",
            destinations: .iOS,
            product: .app,
            bundleId:
                "com.indextrown.Haruhancut.adminfeature.demo",
            deploymentTargets: .iOS("17.0"),
            infoPlist:
                .extendingDefault(
                    with: [
                        "UILaunchScreen": [:],
                        "UIUserInterfaceStyle":
                            "Dark",
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
                    name: "AdminFeature"
                ),
                .target(
                    name:
                        "AdminFeatureInterface"
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
            name: "AdminFeatureTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId:
                "com.indextrown.Haruhancut.adminfeature.tests",
            deploymentTargets: .iOS("17.0"),
            sources: ["Tests/Sources/**"],
            resources: [],
            dependencies: [
                .target(
                    name: "AdminFeature"
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
    ],
    schemes: [
        .scheme(
            name: "AdminFeature",
            shared: true,
            buildAction:
                .buildAction(
                    targets: ["AdminFeature"]
                ),
            testAction: .targets(
                ["AdminFeatureTests"],
                configuration: "Debug"
            )
        ),
        .scheme(
            name: "AdminFeatureDemo",
            shared: true,
            buildAction:
                .buildAction(
                    targets: [
                        "AdminFeatureDemo",
                    ]
                ),
            runAction: .runAction(
                configuration: "Debug"
            )
        ),
    ]
)
