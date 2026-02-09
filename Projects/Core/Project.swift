
// Core 프레임워크 = 영화 제작 회사
// RxSwift = 영화 촬영에 필수인 카메라

// 상황:
// - Core가 RxSwift로 뭔가를 만들고 있다
// - CoreTests가 Core를 테스트하려면, Core가 만든 것을 실행해야 한다
// - 근데 Core가 RxSwift(카메라)를 켜려고 하는데, CoreTests가 RxSwift를 몰라서 오류 발생! 
//   → "RXDelegateProxy가 뭔데?" (심볼을 못 찾음)

// 해결책:
// - CoreTests도 RxSwift를 알아야 한다 (직접 링크)
// - 그럼 Core가 RxSwift를 쓰려고 할 때, CoreTests가 "아, 이거구나" 하고 지원할 수 있다

import ProjectDescription

let project = Project(
    name: "Core",
    targets: [
    
        // MARK: - Core / Domain Framework
        .target(
            name: "Core",
            destinations: .iOS,
            product: .framework, // 필요하면 .staticFramework 로 변경 가능
            bundleId: "com.indextrown.Haruhancut.core",
            deploymentTargets: .iOS("17.0"),
            sources: ["Sources/**"],
            resources: [],
            dependencies: [
                .project(target: "ThirdPartyLibs", path: "../Shared/ThirdPartyLibs")
            ]
        ),

        // MARK: - Unit Tests
        .target(
            name: "CoreTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.indextrown.Haruhancut.core.tests",
            deploymentTargets: .iOS("17.0"),
            sources: ["Tests/Sources/**"],
            resources: [],
            dependencies: [
                .target(name: "Core"),  // 테스트할 대상 모듈 지정
            ]
        ),

        // MARK: - Testing
        // .target(
        //     name: "CoreTesting",
        //     destinations: .iOS,
        //     product: .framework,
        //     bundleId: "com.indextrown.Haruhancut.core.testing",
        //     deploymentTargets: .iOS("17.0"),
        //     sources: ["Testing/Sources/**"],
        //     resources: [],
        //     dependencies: [
        //         .target(name: "Core"),
        //     ]
        // ),
    ],
    schemes: [
        .scheme(
            name: "Core",
            shared: true,
            buildAction: .buildAction(targets: ["Core"]),
            testAction: .targets(
                ["CoreTests"],
                configuration: "Debug"
            )
        )
    ]
)

