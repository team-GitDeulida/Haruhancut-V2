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
                .external(name: "RxSwift"),
                .external(name: "RxCocoa"),
                .external(name: "RxRelay"),
                .external(name: "RxTest"),
                .external(name: "RxBlocking"),
                .external(name: "Lottie"),
                .external(name: "KakaoSDK"),
                .external(name: "RxKakaoSDK"),
                .external(name: "FirebaseAuth"),
                .external(name: "FirebaseDatabase")
            ]
        ),
    ]
)

