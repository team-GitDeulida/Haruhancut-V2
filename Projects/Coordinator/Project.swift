import ProjectDescription

let project = Project(
    name: "Coordinator",
    targets: [
    
        // MARK: - Coordinator / Domain Framework
        .target(
            name: "Coordinator",
            destinations: .iOS,
            product: .staticFramework, // 필요하면 .staticFramework 로 변경 가능
            bundleId: "com.indextrown.Haruhancut.coordinator",
            deploymentTargets: .iOS("17.0"),
            sources: ["Sources/**"],
            resources: [],
            dependencies: [
                .project(target: "AuthFeature", path: "../Features/AuthFeature"),
                .project(target: "HomeFeatureV2", path: "../Features/HomeFeatureV2"),
                .project(target: "HomeFeatureV2Interface", path: "../Features/HomeFeatureV2"),
                .project(target: "HomeFeatureV3", path: "../Features/HomeFeatureV3"),
                .project(target: "HomeFeatureV3Interface", path: "../Features/HomeFeatureV3"),
                .project(target: "OnboardingFeature", path: "../Features/OnboardingFeature"),
                .project(target: "ProfileFeature", path: "../Features/ProfileFeature"),
                .project(target: "ProfileFeatureV2", path: "../Features/ProfileFeatureV2"),
                .project(target: "MemberFeature", path: "../Features/MemberFeature"),
                .project(target: "MemberFeatureV2", path: "../Features/MemberFeatureV2"),
                .project(target: "ImageFeature", path: "../Features/ImageFeature"),
                .project(target: "Core", path: "../Core"),
                .project(target: "ThirdPartyLibs", path: "../Shared/ThirdPartyLibs")
            ]
        ),
    ]
)
