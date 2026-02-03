import ProjectDescription

let project = Project(
    name: "App",
    targets: [
        .target(
            name: "App",
            destinations: [.iPhone, .iPad, .macWithiPadDesign],
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

                // URL Schemes 
                "CFBundleURLTypes": [
                    // Kakao
                    [
                        "CFBundleTypeRole": "Editor",
                        "CFBundleURLSchemes": [
                            "kakao$(KAKAO_NATIVE_APP_KEY)"
                        ]
                    ],

                    // Firebase Phone Auth / Google
                    [
                        "CFBundleTypeRole": "Editor",
                        "CFBundleURLSchemes": [
                            // ⬇️ GoogleService-Info.plist의 REVERSED_CLIENT_ID 값
                            "$(GOOGLE_REVERSED_CLIENT_ID)"
                        ]
                    ]
                ],

                // Kakao SDK 필수 쿼리 스킴
                "LSApplicationQueriesSchemes": [
                    "kakaokompassauth",
                    "kakaolink",
                    "kakaoplus"
                ],

                // Kakao Native App Key (핵심)
                "KAKAO_NATIVE_APP_KEY": "$(KAKAO_NATIVE_APP_KEY)",
            ]),
            
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            entitlements: .file(path: "App.entitlements"),
            dependencies: [
                // // Feature 의존성은 나중에 추가
                // .project(target: "AuthFeature", path: "../Features/AuthFeature"),
                // .project(target: "OnboardingFeature", path: "../Features/OnboardingFeature"),
                // .project(target: "ProfileFeature", path: "../Features/ProfileFeature"),
                // // .project(target: "DSKit", path: "../UI/DSKit")
                // .project(target: "Core", path: "../Core"),
                // .project(target: "Data", path: "../Data"),

                .project(target: "Coordinator", path: "../Coordinator"),
                .project(target: "Data", path: "../Data"),
                .project(target: "ThirdPartyLibs", path: "../Shared/ThirdPartyLibs"),
                // .external(name: "FirebaseCore"),
                // .external(name: "FirebaseAuth"),
                // .external(name: "FirebaseDatabase"),
                // .external(name: "FirebaseStorage"),
                // .external(name: "FirebaseMessaging")
            ],
            settings: .settings(
                base: [
                    // 🔑 Simulator + Device 둘 다 허용
                    "SUPPORTED_PLATFORMS": "iphonesimulator iphoneos",

                    // 🔑 CI에서 arm64 simulator 차단 금지
                    "EXCLUDED_ARCHS[sdk=iphonesimulator*]": "",

                    // 안정화
                    "ONLY_ACTIVE_ARCH": "NO"
                ],
                configurations: [
                    .debug(name: "Debug", xcconfig: "../Shared/Configs/Shared.xcconfig"),
                    .release(name: "Release", xcconfig: "../Shared/Configs/Shared.xcconfig"),
                ]
                // base: [
                //     "CODE_SIGN_STYLE": "Automatic",
                //     "DEVELOPMENT_TEAM": "LGX4B4WC66" // ← 여기에 Team ID
                // ]
            )
        )
    ]
)
