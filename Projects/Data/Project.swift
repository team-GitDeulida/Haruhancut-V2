import ProjectDescription

let project = Project(
    name: "Data",
    targets: [
    
        // MARK: - Data / Domain Framework
        .target(
            name: "Data",
            destinations: .iOS,
            product: .staticFramework, // 필요하면 .staticFramework 로 변경 가능
            bundleId: "com.indextrown.Haruhancut.data",
            deploymentTargets: .iOS("17.0"),
            sources: ["Sources/**"],
            resources: [],
            dependencies: []
        ),

        // MARK: - Unit Tests
        .target(
            name: "DataTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.indextrown.Haruhancut.data.tests",
            deploymentTargets: .iOS("17.0"),
            sources: ["Tests/Sources/**"],
            resources: [],
            dependencies: [
                .target(name: "Data"),
                .target(name: "DataTesting")
            ]
        ),

        // MARK: - Testing
        .target(
            name: "DataTesting",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.indextrown.Haruhancut.data.testing",
            deploymentTargets: .iOS("17.0"),
            sources: ["Testing/Sources/**"],
            resources: [],
            dependencies: [
                .target(name: "Data"),
            ]
        ),
    ]
)

