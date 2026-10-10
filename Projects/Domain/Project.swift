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
        .target(
            name: "DomainTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.indextrown.Haruhancut.domain.tests",
            deploymentTargets: .iOS("17.0"),
            sources: ["Tests/Sources/**"],
            resources: [],
            dependencies: [
                .target(name: "Domain"),
                .project(target: "Core", path: "../Core"),
                .project(target: "ThirdPartyLibs", path: "../Shared/ThirdPartyLibs")
            ]
        ),

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
    ],
    schemes: [
        .scheme(
            name: "Domain",
            shared: true,
            buildAction: .buildAction(targets: ["Domain"]),
            testAction: .targets(["DomainTests"], configuration: "Debug")
        )
    ]
)
