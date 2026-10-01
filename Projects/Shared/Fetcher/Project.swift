import ProjectDescription

let project = Project(
    name: "Fetcher",
    targets: [
        .target(
            name: "Fetcher",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.indextrown.Haruhancut.fetcher",
            deploymentTargets: .iOS("17.0"),
            sources: ["Sources/**"],
            resources: [],
            dependencies: [
                .external(name: "RxSwift")
            ]
        ),
        .target(
            name: "FetcherTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.indextrown.Haruhancut.fetcher.tests",
            deploymentTargets: .iOS("17.0"),
            sources: ["Tests/Sources/**"],
            resources: [],
            dependencies: [
                .target(name: "Fetcher")
            ]
        )
    ],
    schemes: [
        .scheme(
            name: "Fetcher",
            shared: true,
            buildAction: .buildAction(targets: ["Fetcher"]),
            testAction: .targets(
                ["FetcherTests"],
                configuration: "Debug"
            )
        )
    ]
)
