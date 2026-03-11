import ProjectDescription

let project = Project(
    name: "WidgetSupport",
    targets: [
    
        // MARK: - WidgetSupport / Domain Framework
        .target(
            name: "WidgetSupport",
            destinations: .iOS,
            product: .staticFramework, // 필요하면 .staticFramework 로 변경 가능
            bundleId: "com.indextrown.Haruhancut.widgetsupport",
            deploymentTargets: .iOS("17.0"),
            sources: ["Sources/**"],
            resources: [],
            dependencies: [
                .project(target: "Domain", path: "../../Domain")
            ]
        ),

        // MARK: - Unit Tests
        // .target(
        //     name: "WidgetSupportTests",
        //     destinations: .iOS,
        //     product: .unitTests,
        //     bundleId: "com.indextrown.Haruhancut.widgetsupport.tests",
        //     deploymentTargets: .iOS("17.0"),
        //     sources: ["Tests/Sources/**"],
        //     resources: [],
        //     dependencies: [
        //         .target(name: "WidgetSupport"),
        //         .target(name: "WidgetSupportTesting")
        //     ]
        // ),

        // MARK: - Testing
        // .target(
        //     name: "WidgetSupportTesting",
        //     destinations: .iOS,
        //     product: .framework,
        //     bundleId: "com.indextrown.Haruhancut.widgetsupport.testing",
        //     deploymentTargets: .iOS("17.0"),
        //     sources: ["Testing/Sources/**"],
        //     resources: [],
        //     dependencies: [
        //         .target(name: "WidgetSupport"),
        //     ]
        // ),
    ]
)

