import ProjectDescription

let workspace = Workspace(
    name: "Haruhancut",
    projects: [
        "Projects/App",
        "Projects/Coordinator",
        "Projects/Features/*",
        "Projects/Domain" ,
        "Projects/Core" ,
        "Projects/Shared/*"
    ]
)



    // ,
    // schemes: [
    //     .scheme(
    //         name: "Haruhancut-Tests",
    //         shared: true,

    //         // 1️⃣ 빌드 대상 (경로 필수)
    //         buildAction: .buildAction(
    //             targets: [
    //                 .project(
    //                     path: "Projects/Core",
    //                     target: "Core"
    //                 ),
    //                 .project(
    //                     path: "Projects/Core",
    //                     target: "CoreTests"
    //                 )
    //             ]
    //         )
    //     )
    // ]