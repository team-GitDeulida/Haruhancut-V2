import ProjectDescription

let project = Project(
    name: "Auth",
    targets: [
    
        // MARK: - Feature Framework
        .target(
            name: "Auth",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.indextrown.Haruhancut.auth",
            deploymentTargets: .iOS("17.0"),
            sources: ["Sources/**"],
            resources: [],
            dependencies: [
                .project(target: "DSKit", path: "../../UI/DSKit")
            ]
        ),
        
        // MARK: - Interface Framework
        .target(
            name: "AuthInterface",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.indextrown.Haruhancut.auth.interface",
            deploymentTargets: .iOS("17.0"),
            sources: ["Interface/Sources/**"],
            resources: [],
            dependencies: []
        ),
        
        // MARK: - Demo App
        .target(
            name: "AuthDemo",
            destinations: .iOS,
            product: .app,
            bundleId: "com.indextrown.Haruhancut.auth.demo",
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
                .target(name: "Auth"),
                .project(target: "DSKit", path: "../../UI/DSKit")
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

        // MARK: - Tests
        .target(
            name: "AuthTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.indextrown.Haruhancut.auth.tests",
            deploymentTargets: .iOS("17.0"),
            sources: ["Tests/Sources/**"],
            resources: [],
            dependencies: [
                .target(name: "Auth"),
                .target(name: "AuthTesting")
            ]
        ),

        // MARK: - Testing
        .target(
            name: "AuthTesting",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.indextrown.Haruhancut.auth.testing",
            deploymentTargets: .iOS("17.0"),
            sources: ["Testing/Sources/**"],
            resources: [],
            dependencies: [
                .target(name: "AuthInterface")
            ]
        ),
    ]
)

