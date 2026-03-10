import ProjectDescription

let baseSettings: SettingsDictionary = [
    "CODE_SIGN_STYLE": "Automatic",
    "DEVELOPMENT_TEAM": "LGX4B4WC66"
]

let project = Project(
    name: "HaruhancutWidget",
    targets: [
        .target(
            name: "HaruhancutWidget",
            destinations: [.iPhone],
            product: .appExtension,
            bundleId: "com.indextrown.Haruhancut.WidgetExtension",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: [
                "NSExtension": [
                    "NSExtensionPointIdentifier": "com.apple.widgetkit-extension"
                ]
            ]),
            sources: ["Sources/**"],
            resources: ["Resources/**"],

            // entitlements 추가
            entitlements: .file(path: "HaruhancutWidget.entitlements"),

            dependencies: [
                .project(target: "WidgetSupport", path: "../../Shared/WidgetSupport")
            ],

            settings: .settings(
                base: baseSettings
            )
        )
    ]
)