import ProjectDescription

// command line 입력
// ex) tuist scaffold feature --name "모듈명"

let nameAttribute: Template.Attribute = .required("name")
let template = Template(
    description: "Make MicroFeature Module",
    attributes: [nameAttribute],
    items: [
        // MARK: - Project.swift
        .file(path: "Projects/Features/\(nameAttribute)/Project.swift", templatePath: "stencil/Project.stencil"),
        
        // MARK: - Sources
        // feature 모듈의 실제 기능 구현(보통 화면 단위로 분리)
        .file(path: "Projects/Features/\(nameAttribute)/Sources/Empty.swift", templatePath: "stencil/Empty.stencil"),
        
        // MARK: - Interface
        // feature 모듈의 외부에 공개 할 interface
        .file(path: "Projects/Features/\(nameAttribute)/Interface/Sources/Empty.swift", templatePath: "stencil/Empty.stencil"),

        // MARK: - Tests
        // Unit Tests 작업을 위한 모듈
        .file(path: "Projects/Features/\(nameAttribute)/Tests/Sources/Empty.swift", templatePath: "stencil/Empty.stencil"),

        // Testing 
        // interface 모듈의 Mocking을 제공
        .file(path: "Projects/Features/\(nameAttribute)/Testing/Sources/Empty.swift", templatePath: "stencil/Empty.stencil"),

        // MARK: - Examples(Demo App)
        // 기능을 테스트할 수 있는 작은 단위의 앱 target(빠르게 일부만 빌드/배포 가능)
        .file(path: "Projects/Features/\(nameAttribute)/Demo/AppDelegate.swift", templatePath: "stencil/AppDelegate.stencil"),
        .file(path: "Projects/Features/\(nameAttribute)/Demo/SceneDelegate.swift", templatePath: "stencil/SceneDelegate.stencil"),
        .file(path: "Projects/Features/\(nameAttribute)/Demo/MainViewController.swift", templatePath: "stencil/MainViewController.stencil")
    ]
)
