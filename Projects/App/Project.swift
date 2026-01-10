import ProjectDescription

let project = Project(
    name: "App",
    targets: [
        .target(
            name: "App",
            destinations: .iOS,
            product: .app,
            productName: "Haruhancut",
            bundleId: "com.indextrown.Haruhancut",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: [
                // 앱 이름 설정
                "CFBundleDisplayName": "하루한컷",

                // Storyboard 미사용
                "UILaunchScreen": [:],

                 // Scene 설정 핵심
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
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            dependencies: [
                // Feature 의존성은 나중에 추가
                .project(target: "AuthFeature", path: "../Features/AuthFeature"),
                .project(target: "DSKit", path: "../UI/DSKit")
            ],
            settings: .settings(
                configurations: [
                    .debug(name: "Debug", xcconfig: "../Shared/Configs/Shared.xcconfig"),
                    .release(name: "Release", xcconfig: "../Shared/Configs/Shared.xcconfig")
                ]
                // base: [
                //     "CODE_SIGN_STYLE": "Automatic",
                //     "DEVELOPMENT_TEAM": "LGX4B4WC66" // ← 여기에 Team ID
                // ]
            )
        )
    ]
)