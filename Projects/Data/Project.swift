import ProjectDescription

let project = Project(
    name: "Data",
    targets: [
    
        // MARK: - Data / Domain Framework
        .target(
            name: "Data",
            destinations: .iOS,
            product: .framework, // 필요하면 .staticFramework 로 변경 가능
            bundleId: "com.indextrown.Haruhancut.data",
            deploymentTargets: .iOS("17.0"),
            sources: ["Sources/**"],
            resources: [],
            dependencies: [
                .project(target: "Domain", path: "../Domain"),
                .project(target: "ThirdPartyLibs", path: "../Shared/ThirdPartyLibs")
            ]
        ),

        // MARK: - Unit Tests
        .target(
            name: "DataTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.indextrown.Haruhancut",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: [
                // 🔥 Firebase Messaging Swizzling 완전 차단
                "FirebaseAppDelegateProxyEnabled": false,

                // 🔥 XCTest 환경에서 Notification 접근 방지
                "UIApplicationSceneManifest": [:]
            ]),
            sources: ["Tests/Sources/**"],
            resources: [
                "../Shared/Firebase/GoogleService-Info.plist"
            ],
            dependencies: [
                .target(name: "Data"),
                // .external(name: "FirebaseCore"),
                // .external(name: "FirebaseAuth"),
                // .external(name: "FirebaseDatabase"),
                // .external(name: "FirebaseStorage"),
                // .project(target: "ThirdPartyLibs", path: "../Shared/ThirdPartyLibs")
            ]
        ),
    ],
    schemes: [
        .scheme(
            name: "Data",
            shared: true,
            buildAction: .buildAction(targets: ["Data"]),
            testAction: .targets(
                ["DataTests"],
                configuration: "Debug"
            )
        )
    ]
)

