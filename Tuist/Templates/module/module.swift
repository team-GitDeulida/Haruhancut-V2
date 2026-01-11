import ProjectDescription

// command line 입력
// ex) tuist scaffold module --dir "경로" --name "모듈명"

let nameAttributeModule: Template.Attribute = .required("name")

// dir 매개변수 안쓰면 Project/..
// dir 매개변수 받으면 Project/dir경로/..
let dirAttribute: Template.Attribute = .optional("dir", default: ".")

let templateModule = Template(
    description: "Make MicroFeature Module",
    attributes: [nameAttributeModule, dirAttribute],
    items: [
        // MARK: - Project.swift
        .file(path: "Projects/\(dirAttribute)/\(nameAttributeModule)/Project.swift", templatePath: "stencil/Project.stencil"),
        
        // MARK: - Sources
        // 모듈의 실제 기능 구현(보통 화면 단위로 분리)
        .file(path: "Projects/\(dirAttribute)/\(nameAttributeModule)/Sources/Empty.swift", templatePath: "stencil/Empty.stencil"),

        // MARK: - Tests
        // Unit Tests 작업을 위한 모듈
        .file(path: "Projects/\(dirAttribute)/\(nameAttributeModule)/Tests/Sources/Empty.swift", templatePath: "stencil/Empty.stencil"),

        // MARK: - Testing
        // interface 모듈의 Mocking을 제공
        .file(path: "Projects/\(dirAttribute)/\(nameAttributeModule)/Testing/Sources/Empty.swift", templatePath: "stencil/Empty.stencil"),
    ]
)
