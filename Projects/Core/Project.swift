import ProjectDescription

let project = Project(
    name: "Core",
    targets: [
    
        // MARK: - Core / Domain Framework
        .target(
            name: "Core",
            destinations: .iOS,
            product: .staticFramework, // 필요하면 .staticFramework 로 변경 가능
            bundleId: "com.indextrown.Haruhancut.core",
            deploymentTargets: .iOS("17.0"),
            sources: ["Sources/**"],
            resources: [],
            dependencies: []
        ),

        // MARK: - Unit Tests
        // .target(
        //     name: "CoreTests",
        //     destinations: .iOS,
        //     product: .unitTests,
        //     bundleId: "com.indextrown.Haruhancut.core.tests",
        //     deploymentTargets: .iOS("17.0"),
        //     sources: ["Tests/Sources/**"],
        //     resources: [],
        //     dependencies: [
        //         .target(name: "Core"),
        //         .target(name: "CoreTesting")
        //     ]
        // ),

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
    ]
)

