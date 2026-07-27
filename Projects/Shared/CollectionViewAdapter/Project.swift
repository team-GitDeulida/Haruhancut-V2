import ProjectDescription

let project = Project(
    name: "CollectionViewAdapter",
    targets: [
        .target(
            name: "CollectionViewAdapter",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.indextrown.Haruhancut.collectionviewadapter",
            deploymentTargets: .iOS("17.0"),
            sources: ["Sources/**"],
            resources: [],
            dependencies: []
        ),
        .target(
            name: "CollectionViewAdapterTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.indextrown.Haruhancut.collectionviewadapter.tests",
            deploymentTargets: .iOS("17.0"),
            sources: ["Tests/Sources/**"],
            resources: [],
            dependencies: [
                .target(name: "CollectionViewAdapter")
            ]
        ),
        .target(
            name: "CollectionViewAdapterDemo",
            destinations: .iOS,
            product: .app,
            bundleId: "com.indextrown.Haruhancut.collectionviewadapter.demo",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: [
                "UILaunchScreen": [:]
            ]),
            sources: ["Demo/**"],
            resources: [],
            dependencies: [
                .target(name: "CollectionViewAdapter"),
                .external(name: "DifferenceKit")
            ],
            settings: .settings(
                configurations: [
                    .debug(
                        name: "Debug",
                        xcconfig: "../Configs/Shared.xcconfig"
                    ),
                    .release(
                        name: "Release",
                        xcconfig: "../Configs/Shared.xcconfig"
                    )
                ]
            )
        )
    ],
    schemes: [
        .scheme(
            name: "CollectionViewAdapter",
            shared: true,
            buildAction: .buildAction(targets: ["CollectionViewAdapter"]),
            testAction: .targets(
                ["CollectionViewAdapterTests"],
                configuration: "Debug"
            )
        ),
        .scheme(
            name: "CollectionViewAdapterDemo",
            shared: true,
            buildAction: .buildAction(targets: ["CollectionViewAdapterDemo"]),
            runAction: .runAction(configuration: "Debug")
        )
    ]
)
