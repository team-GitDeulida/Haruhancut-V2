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
                .project(target: "Core", path: "../../Core"),
                .project(target: "ThirdPartyLibs", path: "../../Shared/ThirdPartyLibs")
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
                .target(name: "DSKit"),
                .project(target: "ThirdPartyLibs", path: "../../Shared/ThirdPartyLibs")
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
                // Basic Info
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
                ],

                // 폰트 추가
                "UIAppFonts": .array([
                    .string("NanumMyeongjo-Regular.ttf"),
                    .string("RacingSansOne-Regular.ttf"),
                    .string("Pretendard-Black.otf"),
                    .string("Pretendard-Bold.otf"),
                    .string("Pretendard-ExtraBold.otf"),
                    .string("Pretendard-ExtraLight.otf"),
                    .string("Pretendard-Light.otf"),
                    .string("Pretendard-Medium.otf"),
                    .string("Pretendard-Regular.otf"),
                    .string("Pretendard-SemiBold.otf"),
                    .string("Pretendard-Thin.otf")
                ]),
            ]),
            sources: ["Demo/**"],
            resources: [
                "../../Shared/Resources/Fonts/**"
            ],
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
