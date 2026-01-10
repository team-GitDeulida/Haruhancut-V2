import ProjectDescription

// command line 입력
// ex) tuist scaffold ui --name "모듈명"

let nameAttributeUI: Template.Attribute = .required("name")
let templateUI = Template(
    description: "Make MicroFeature UI Module",
    attributes: [nameAttributeUI],
    items: [
        // MARK: - Project.swift
        .file(path: "Projects/UI/\(nameAttributeUI)/Project.swift", templatePath: "stencil/Project.stencil"),

        // MARK: - Sources
        .file(
            path: "Projects/UI/\(nameAttributeUI)/Sources/Empty.swift",
            templatePath: "stencil/Empty.stencil"
        ),

        // MARK: - Resources
        .file(
            path: "Projects/UI/\(nameAttributeUI)/Resources/Assets.xcassets/Contents.json",
            templatePath: "stencil/xcassets/Contents.json"
        ),
        .file(
            path: "Projects/UI/\(nameAttributeUI)/Resources/Colors.xcassets/Contents.json",
            templatePath: "stencil/xcassets/Contents.json"
        ),

        // MARK: - Tests
        .file(
            path: "Projects/UI/\(nameAttributeUI)/Tests/Sources/Empty.swift",
            templatePath: "stencil/Empty.stencil"
        ),

        // MARK: - Demo App
        .file(path: "Projects/UI/\(nameAttributeUI)/Demo/AppDelegate.swift", templatePath: "stencil/AppDelegate.stencil"),
        .file(path: "Projects/UI/\(nameAttributeUI)/Demo/SceneDelegate.swift", templatePath: "stencil/SceneDelegate.stencil"),
        .file(path: "Projects/UI/\(nameAttributeUI)/Demo/MainViewController.swift", templatePath: "stencil/MainViewController.stencil")
    ]
)
