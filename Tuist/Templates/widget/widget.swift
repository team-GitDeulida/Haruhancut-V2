import ProjectDescription

let template = Template(
    description: "Generate Widget module",
    attributes: [
        .required("name")
    ],
    items: [
        // Project
        .file(
            path: "Projects/Widget/{{ name }}/Project.swift",
            templatePath: "Project.stencil"
        ),

        // Sources
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

        // Resources
        .file(
            path: "Projects/Widget/{{ name }}/Resources/Info.plist",
            templatePath: "InfoPlist.stencil"
        ),

        // Assets
        .file(
            path: "Projects/Widget/{{ name }}/Resources/Assets.xcassets/Contents.json",
            templatePath: "AssetsContents.stencil"
        ),

        // Widget Preview
        .file(
            path: "Projects/Widget/{{ name }}/Resources/Assets.xcassets/widgetPreview.imageset/Contents.json",
            templatePath: "WidgetPreviewContents.stencil"
        ),

        .file(
            path: "Projects/Widget/{{ name }}/Resources/.gitkeep",
            templatePath: "Empty.stencil"
        )
    ]
)