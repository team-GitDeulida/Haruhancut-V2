import SwiftUI

/// README의 Source/Result와 캡처 전용 Demo 화면을 연결합니다.
enum ReadmeCaptureRoute: String, CaseIterable, Hashable {
    case vertical
    case grid
    case mixedSections = "mixed-sections"

    var title: String {
        switch self {
        case .vertical:
            "Vertical"
        case .grid:
            "Grid"
        case .mixedSections:
            "Horizontal + Vertical"
        }
    }

    var caption: String {
        switch self {
        case .vertical:
            "하나의 Section에 기본 목록을 구성합니다"
        case .grid:
            "카드를 2열 Grid로 배치합니다"
        case .mixedSections:
            "첫 Section은 가로, 두 번째는 세로로 구성합니다"
        }
    }

    var symbolName: String {
        switch self {
        case .vertical:
            "list.bullet"
        case .grid:
            "square.grid.2x2.fill"
        case .mixedSections:
            "rectangle.3.group.fill"
        }
    }

    var tint: Color {
        switch self {
        case .vertical:
            .blue
        case .grid:
            .orange
        case .mixedSections:
            .purple
        }
    }

    @MainActor
    @ViewBuilder
    var destination: some View {
        switch self {
        case .vertical:
            ReadmeVerticalViewController()
                .toSwiftUI()
                .readmeCaptureNavigation(title: title)

        case .grid:
            ReadmeGridViewController()
                .toSwiftUI()
                .readmeCaptureNavigation(title: title)

        case .mixedSections:
            ReadmeMixedSectionsViewController()
                .toSwiftUI()
                .readmeCaptureNavigation(title: title)
        }
    }
}

/// 캡처할 화면으로 바로 이동하면서 Demo와 같은 back button을 유지합니다.
struct ReadmeCaptureRootView: View {
    @State private var path: [ReadmeCaptureRoute]

    init(route: ReadmeCaptureRoute) {
        _path = State(initialValue: [route])
    }

    var body: some View {
        NavigationStack(path: $path) {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
                .navigationDestination(
                    for: ReadmeCaptureRoute.self
                ) { route in
                    route.destination
                }
        }
        .tint(.yellow)
    }
}

private extension View {
    func readmeCaptureNavigation(
        title: String
    ) -> some View {
        navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
    }
}
