import ProjectDescription

let project = Project(
    name: "DSKit",
    targets: [
    
        // MARK: - UI Framework
        .target(
            name: "DSKit",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.indextrown.Haruhancut.ui.dskit",
            deploymentTargets: .iOS("17.0"),
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            dependencies: [
                .project(target: "Core", path: "../../Core")
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
        
        // MARK: - UI Tests
        .target(
            name: "DSKitTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.indextrown.Haruhancut.ui.dskit.tests",
            deploymentTargets: .iOS("17.0"),
            sources: ["Tests/Sources/**"],
            resources: [],
            dependencies: [
                .target(name: "DSKit")
            ]
        ),
        
        // MARK: - UI Demo App (Optional but Recommended)
        .target(
            name: "DSKitDemo",
            destinations: .iOS,
            product: .app,
            bundleId: "com.indextrown.Haruhancut.ui.dskit.demo",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: [
                "UILaunchScreen": [:],
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
                ]
            ]),
            sources: ["Demo/**"],
            resources: [],
            dependencies: [
                .target(name: "DSKit")
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
        )
    ]
)
