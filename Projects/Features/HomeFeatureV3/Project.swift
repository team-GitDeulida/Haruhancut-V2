import ProjectDescription

let project = Project(
    name: "HomeV3",
    targets: [
        .target(
            name: "HomeFeatureV3",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "com.indextrown.Haruhancut.homefeaturev3",
            deploymentTargets: .iOS("17.0"),
            sources: ["Sources/**"],
            resources: [],
            dependencies: [
                .target(name: "HomeFeatureV3Interface"),
                .project(
                    target: "CollectionViewAdapter",
                    path: "../../Shared/CollectionViewAdapter"
                ),
                .project(
                    target: "DSKit",
                    path: "../../Shared/DSKit"
                ),
                .project(
                    target: "Data",
                    path: "../../Data"
                ),
                .project(
                    target: "ThirdPartyLibs",
                    path: "../../Shared/ThirdPartyLibs"
                ),
                .project(
                    target: "WidgetSupport",
                    path: "../../Shared/WidgetSupport"
                ),
            ]
        ),
        .target(
            name: "HomeFeatureV3Interface",
            destinations: .iOS,
            product: .framework,
            bundleId:
                "com.indextrown.Haruhancut.homefeaturev3.interface",
            deploymentTargets: .iOS("17.0"),
            sources: ["Interface/Sources/**"],
            resources: [],
            dependencies: [
                .project(
                    target: "Domain",
                    path: "../../Domain"
                ),
            ]
        ),
        .target(
            name: "HomeFeatureV3Demo",
            destinations: .iOS,
            product: .app,
            bundleId:
                "com.indextrown.Haruhancut.homefeaturev3.demo",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: [
                "UILaunchScreen": [:],
                "UIUserInterfaceStyle": "Dark",
                "UISupportedInterfaceOrientations": [
                    "UIInterfaceOrientationPortrait",
                ],
                "UIApplicationSceneManifest": [
                    "UIApplicationSupportsMultipleScenes": true,
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
            ]),
            sources: ["Demo/Sources/**"],
            resources: [],
            dependencies: [
                .target(name: "HomeFeatureV3"),
                .target(name: "HomeFeatureV3Interface"),
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
                    path: "../../Shared/ThirdPartyLibs"
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
            name: "HomeFeatureV3Tests",
            destinations: .iOS,
            product: .unitTests,
            bundleId:
                "com.indextrown.Haruhancut.homefeaturev3.tests",
            deploymentTargets: .iOS("17.0"),
            sources: ["Tests/Sources/**"],
            resources: [],
            dependencies: [
                .target(name: "HomeFeatureV3"),
            ]
        ),
    ],
    schemes: [
        .scheme(
            name: "HomeFeatureV3",
            shared: true,
            buildAction:
                .buildAction(
                    targets: ["HomeFeatureV3"]
                ),
            testAction:
                .targets(
                    ["HomeFeatureV3Tests"],
                    configuration: "Debug"
                )
        ),
        .scheme(
            name: "HomeFeatureV3Demo",
            shared: true,
            buildAction:
                .buildAction(
                    targets: ["HomeFeatureV3Demo"]
                ),
            runAction:
                .runAction(
                    configuration: "Debug"
                )
        ),
    ]
)
