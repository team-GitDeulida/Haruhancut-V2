import ProjectDescription

let baseSettings: SettingsDictionary = [
    "CODE_SIGN_STYLE": "Automatic",
    "DEVELOPMENT_TEAM": "LGX4B4WC66"
]

let project = Project(
    name: "App",
    targets: [
        .target(
            name: "App",
            destinations: [.iPhone],
            product: .app,
            productName: "Haruhancut",
            bundleId: "com.indextrown.Haruhancut",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: [
                // 앱 이름 설정
                "CFBundleDisplayName": "하루한컷",
                
                // 사진 촬영 권한
                "NSCameraUsageDescription": "하루한컷은 일상 사진을 촬영해 가족·친구와 공유하기 위해 카메라 권한이 필요합니다.",
                
                // 사진 저장 권한
                "NSPhotoLibraryAddUsageDescription": "하루한컷은 사진을 사용자의 앨범에 저장하기 위해 권한이 필요합니다.",
                
                // 앨범 불러오기 권한
                "NSPhotoLibraryUsageDescription": "하루한컷은 사진을 불러오기 위해 사진 보관함 접근 권한이 필요합니다.",
                
                // 다크 모드 강제
                "UIUserInterfaceStyle": "Dark",
                
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
                
                // Landscape Left, right, upsidwDown 제거
                "UISupportedInterfaceOrientations": [
                    "UIInterfaceOrientationPortrait"
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
                .project(target: "Coordinator", path: "../Coordinator"),
                .project(target: "Data", path: "../Data"),
                .project(target: "ThirdPartyLibs", path: "../Shared/ThirdPartyLibs"),
            ],
            settings: .settings(
                configurations: [
                    .debug(name: "Debug", xcconfig: "../Shared/Configs/Shared.xcconfig"),
                    .release(name: "Release", xcconfig: "../Shared/Configs/Shared.xcconfig"),
                ]
                // base: [
                //     "CODE_SIGN_STYLE": "Automatic",
                //     "DEVELOPMENT_TEAM": "LGX4B4WC66" // ← 여기에 Team ID
                // ]
            )
        ),
        .target(
            name: "AppTests",
            destinations: [.iPhone],
            product: .unitTests,
            bundleId: "com.indextrown.Haruhancut.app",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: [
                .target(name: "App")
            ],
            settings: .settings(
                base: [
                    // AppDelegate / UIApplication 사용 가능하게
                    "TEST_HOST": "$(BUILT_PRODUCTS_DIR)/Haruhancut.app/Haruhancut",
                    "BUNDLE_LOADER": "$(TEST_HOST)",
                    "CODE_SIGN_STYLE": "Automatic",
                    "DEVELOPMENT_TEAM": "LGX4B4WC66"
                ]
            )
        ),
        .target(
            name: "AppUITests",
            destinations: [.iPhone],
            product: .uiTests,
            bundleId: "com.indextrown.Haruhancut.app",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["UITests/**"],
            dependencies: [
                .target(name: "App")
            ],
            settings: .settings(
                base: [
                    "CODE_SIGN_STYLE": "Automatic",
                    "DEVELOPMENT_TEAM": "LGX4B4WC66" 
                ]
            )
        )
    ],
    schemes: [
        .scheme(
            name: "App",
            shared: true,
            buildAction: .buildAction(
                targets: ["App"]
            ),
            testAction: .targets(
                ["AppTests", "AppUITests"],
                configuration: "Debug"
            ),
            runAction: .runAction(
                configuration: .debug,
                executable: "App"
            ),
            archiveAction: .archiveAction(
                configuration: .release
            )
        )
    ]
)





// testAction: .targets(
//     ["AppTests"],
//     configuration: "Debug"
// )


                // // Feature 의존성은 나중에 추가
                // .project(target: "AuthFeature", path: "../Features/AuthFeature"),
                // .project(target: "OnboardingFeature", path: "../Features/OnboardingFeature"),
                // .project(target: "ProfileFeature", path: "../Features/ProfileFeature"),
                // // .project(target: "DSKit", path: "../UI/DSKit")
                // .project(target: "Core", path: "../Core"),
                // .project(target: "Data", path: "../Data"),
                                // .external(name: "FirebaseCore"),
                // .external(name: "FirebaseAuth"),
                // .external(name: "FirebaseDatabase"),
                // .external(name: "FirebaseStorage"),
                // .external(name: "FirebaseMessaging")
