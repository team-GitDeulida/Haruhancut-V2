import ProjectDescription

let template = Template(
    description: "Generate Widget module",
    attributes: [
        .required("name")
    ],
    items: [
        .file(
            path: "Projects/Widget/{{ name }}/Project.swift",
            templatePath: "Project.stencil"
        ),
        .file(
            path: "Projects/Widget/{{ name }}/Sources/{{ name }}Widget.swift",
            templatePath: "Widget.stencil"
        ),
        .file(
            path: "Projects/Widget/{{ name }}/Sources/{{ name }}WidgetBundle.swift",
            templatePath: "WidgetBundle.stencil"
        ),
        .file(
            path: "Projects/Widget/{{ name }}/Sources/Provider.swift",
            templatePath: "Provider.stencil"
        ),
        // Resources 폴더 생성
        .file(
            path: "Projects/Widget/{{ name }}/Resources/.gitkeep",
            templatePath: "Empty.stencil"
        )
    ]
)