//
//  domain.swift
//  Manifests
//
//  Created by 김동현 on 1/11/26.
//

import ProjectDescription

// command line 입력
// ex) tuist scaffold domain --name "모듈명"

let nameAttributeDomain: Template.Attribute = .required("name")
let templateDomain = Template(
    description: "Make MicroFeature Domain Module",
    attributes: [nameAttributeDomain],
    items: [
        // MARK: - Project.swift
        .file(path: "Projects/Domain/\(nameAttributeDomain)/Project.swift", templatePath: "stencil/Project.stencil"),
        
        // MARK: - Sources
        .file(
            path: "Projects/Domain/\(nameAttributeDomain)/Sources/Empty.swift",
            templatePath: "stencil/Empty.stencil"
        ),
        
        // MARK: - Domain Tests
        .file(
            path: "Projects/Domain/\(nameAttributeDomain)/Tests/Sources/Empty.swift",
            templatePath: "stencil/Empty.stencil"
        ),
        
        // MARK: - Domain Testing
        .file(path: "Projects/Domain/\(nameAttributeDomain)/Testing/Sources/Empty.swift", templatePath: "stencil/Empty.stencil"),
    ]
)
