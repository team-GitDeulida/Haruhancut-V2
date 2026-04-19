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
                // .external(name: "RxSwift"),
                .external(name: "RxCocoa"),
                // .external(name: "RxRelay"),
                .external(name: "RxDataSources"),
                // .external(name: "RxTest"),
                // .external(name: "RxBlocking"),

                // Kakao
                .external(name: "RxKakaoSDK"),
                
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
                .external(name: "FSCalendar"),

                // TurboListKit
                .external(name: "TurboListKit"),
                .external(name: "CarbonListKit"),
                
            ],
            settings: .settings(
                base: [
                    "OTHER_LDFLAGS": "$(inherited) -ObjC" // 기존 flag 유지하면서 추가 가능
                   //  "OTHER_LDFLAGS": "-ObjC" // 기존 flag 덮어쓰기 가능
                ]
            )
        ),
    ]
)

