import ProjectDescription

let project = Project(
    name: "HomeV2",
    targets: [

        // MARK: - Module Framework
        .target(
            name: "HomeFeatureV2",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "com.indextrown.Haruhancut.homefeaturev2",
            deploymentTargets: .iOS("17.0"),
            sources: ["Sources/**"],
            resources: [],
            dependencies: [
                .target(name: "HomeFeatureV2Interface"),
                .project(target: "DSKit", path: "../../Shared/DSKit"),
                .project(target: "Data", path: "../../Data"),
                .project(target: "ThirdPartyLibs", path: "../../Shared/ThirdPartyLibs"),
                .project(target: "WidgetSupport", path: "../../Shared/WidgetSupport")
            ]
        ),

        // MARK: - ModuleInterface Framework
        .target(
            name: "HomeFeatureV2Interface",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.indextrown.Haruhancut.homefeaturev2.interface",
            deploymentTargets: .iOS("17.0"),
            sources: ["Interface/Sources/**"],
            resources: [],
            dependencies: [
                .project(target: "Domain", path: "../../Domain")
            ]
        ),

        // MARK: - ModuleDemo App
        .target(
            name: "HomeFeatureV2Demo",
            destinations: .iOS,
            product: .app,
            bundleId: "com.indextrown.Haruhancut.homefeaturev2.demo",
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
                .target(name: "HomeFeatureV2Interface"),
                .target(name: "HomeFeatureV2"),
                .target(name: "HomeFeatureV2Testing")
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

        // MARK: - Module Tests
        .target(
            name: "HomeFeatureV2Tests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.indextrown.Haruhancut.homefeaturev2.tests",
            deploymentTargets: .iOS("17.0"),
            sources: ["Tests/Sources/**"],
            resources: [],
            dependencies: [
                .target(name: "HomeFeatureV2"),
                .target(name: "HomeFeatureV2Testing")
            ]
        ),

        // MARK: - Module Testing
        .target(
            name: "HomeFeatureV2Testing",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.indextrown.Haruhancut.homefeaturev2.testing",
            deploymentTargets: .iOS("17.0"),
            sources: ["Testing/Sources/**"],
            resources: [],
            dependencies: [
                .target(name: "HomeFeatureV2Interface")
            ]
        ),
    ]
)
