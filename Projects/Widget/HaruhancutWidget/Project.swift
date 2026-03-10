import ProjectDescription

let debugSettings: SettingsDictionary = [
    "CODE_SIGN_STYLE": "Manual",
    "DEVELOPMENT_TEAM": "LGX4B4WC66",
    "PROVISIONING_PROFILE_SPECIFIER": "match Development com.indextrown.Haruhancut.WidgetExtension",
    "CODE_SIGN_IDENTITY": "Apple Development"
]

let releaseSettings: SettingsDictionary = [
    "CODE_SIGN_STYLE": "Manual",
    "DEVELOPMENT_TEAM": "LGX4B4WC66",
    "PROVISIONING_PROFILE_SPECIFIER": "match AppStore com.indextrown.Haruhancut.WidgetExtension",
    "CODE_SIGN_IDENTITY": "Apple Distribution"
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
                "CFBundleDisplayName": "하루한컷 위젯",
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
                base: [:],
                configurations: [
                    .debug(name: "Debug", settings: debugSettings),
                    .release(name: "Release", settings: releaseSettings)
                ]
            )
        )
    ]
)