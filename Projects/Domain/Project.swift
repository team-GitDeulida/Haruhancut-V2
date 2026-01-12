import ProjectDescription

let project = Project(
    name: "Domain",
    targets: [
    
        // MARK: - Domain Sources
        .target(
            name: "Domain",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.indextrown.Haruhancut.domain",
            deploymentTargets: .iOS("17.0"),
            sources: ["Sources/**"],
            resources: [],
            dependencies: [
                .project(target: "Core", path: "../Core")
            ]
        ),
        
        // MARK: - Domain Tests
        // .target(
        //     name: "DomainTests",
        //     destinations: .iOS,
        //     product: .unitTests,
        //     bundleId: "com.indextrown.Haruhancut.domain.tests",
        //     sources: ["Tests/Sources/**"],
        //     resources: [],
        //     dependencies: [
        //         .target(name: "Domain"),
        //         .target(name: "DomainTesting")
        //     ]
        // ),

        // MARK: - Domain Testing
        // .target(
        //     name: "DomainTesting",
        //     destinations: .iOS,
        //     product: .framework,
        //     bundleId: "com.indextrown.Haruhancut.domain.testing",
        //     sources: ["Testing/Sources/**"],
        //     resources: [],
        //     dependencies: [
        //         .target(name: "Domain"),
        //     ]
        // ),
    ]
)

