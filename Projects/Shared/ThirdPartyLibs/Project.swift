import ProjectDescription

let project = Project(
    name: "ThirdPartyLibs",
    targets: [
    
        // MARK: - ThirdPartyLibs / Domain Framework
        .target(
            name: "ThirdPartyLibs",
            destinations: .iOS,
            product: .framework, // 필요하면 .staticFramework 로 변경 가능
            bundleId: "com.indextrown.Haruhancut.thirdpartylibs",
            deploymentTargets: .iOS("17.0"),
            sources: ["Sources/**"],
            resources: [],
            dependencies: [
                // Rx
                .external(name: "RxSwift"),
                .external(name: "RxCocoa"),
                .external(name: "RxRelay"),
                // .external(name: "RxTest"),
                // .external(name: "RxBlocking"),

                
                // Kakao
                .external(name: "RxKakaoSDK"),
                // .external(name: "KakaoSDK"),
                // .external(name: "KakaoSDKCertCore"),
                
                // Firebase
                .external(name: "FirebaseAuth"),
                .external(name: "FirebaseCore"),
                .external(name: "FirebaseDatabase"),
                .external(name: "FirebaseStorage"),
                .external(name: "FirebaseMessaging"),

                // UI / Utils
                .external(name: "Lottie"),
                .external(name: "ScaleKit"),
                .external(name: "Kingfisher"),
            ],
            settings: .settings(
                base: [
                    "OTHER_LDFLAGS": "-ObjC"
                ]
            )
        ),
    ]
)

