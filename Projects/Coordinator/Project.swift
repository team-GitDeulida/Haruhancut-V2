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
                // Feature 의존성은 나중에 추가
                .project(target: "AuthFeature", path: "../Features/AuthFeature"),
                .project(target: "HomeFeature", path: "../Features/HomeFeature"),
                .project(target: "OnboardingFeature", path: "../Features/OnboardingFeature"),
                .project(target: "ProfileFeature", path: "../Features/ProfileFeature"),
                .project(target: "ImageFeature", path: "../Features/ImageFeature"),
                .project(target: "Core", path: "../Core"),
            ]
        ),
    ]
)

