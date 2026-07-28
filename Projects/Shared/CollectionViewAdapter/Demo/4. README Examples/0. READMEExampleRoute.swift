import SwiftUI

/// README의 Source/Result 예제와 Demo 화면을 같은 순서로 연결합니다.
enum READMEExampleRoute: String, CaseIterable, Hashable {
    case quickStart = "quick-start"
    case sectionLayouts = "section-layouts"
    case snapshotUpdates = "snapshot-updates"
    case componentModifiers = "component-modifiers"
    case prefetchPagination = "prefetch-pagination"
    case swiftUIBridge = "swiftui-bridge"

    var title: String {
        switch self {
        case .quickStart:
            "Quick Start"
        case .sectionLayouts:
            "Section Layouts"
        case .snapshotUpdates:
            "Snapshot Updates"
        case .componentModifiers:
            "Component Modifiers"
        case .prefetchPagination:
            "Prefetch + Pagination"
        case .swiftUIBridge:
            "SwiftUI Bridge"
        }
    }

    var caption: String {
        switch self {
        case .quickStart:
            "Section DSL로 Component 목록을 선언합니다"
        case .sectionLayouts:
            "가로 Carousel과 2열 Grid를 한 화면에 조합합니다"
        case .snapshotUpdates:
            "안정적인 ID로 insert, move, reconfigure를 적용합니다"
        case .componentModifiers:
            "Content capability에 필요한 상호작용만 합성합니다"
        case .prefetchPagination:
            "안정적인 Item ID로 선로딩과 다음 페이지를 연결합니다"
        case .swiftUIBridge:
            "UIKit Component를 SwiftUI 화면에서 그대로 재사용합니다"
        }
    }

    var symbolName: String {
        switch self {
        case .quickStart:
            "list.bullet.rectangle.portrait.fill"
        case .sectionLayouts:
            "rectangle.3.group.fill"
        case .snapshotUpdates:
            "arrow.triangle.2.circlepath"
        case .componentModifiers:
            "hand.tap.fill"
        case .prefetchPagination:
            "arrow.down.forward.and.arrow.up.backward"
        case .swiftUIBridge:
            "swift"
        }
    }

    var tint: Color {
        switch self {
        case .quickStart:
            .blue
        case .sectionLayouts:
            .purple
        case .snapshotUpdates:
            .indigo
        case .componentModifiers:
            .orange
        case .prefetchPagination:
            .teal
        case .swiftUIBridge:
            .pink
        }
    }

    @MainActor
    @ViewBuilder
    var destination: some View {
        switch self {
        case .quickStart:
            READMEQuickStartViewController()
                .toSwiftUI()
                .readmeExampleNavigation(title: title)

        case .sectionLayouts:
            READMESectionLayoutsViewController()
                .toSwiftUI()
                .readmeExampleNavigation(title: title)

        case .snapshotUpdates:
            READMESnapshotUpdatesViewController()
                .toSwiftUI()
                .readmeExampleNavigation(title: title)

        case .componentModifiers:
            READMEComponentModifiersViewController()
                .toSwiftUI()
                .readmeExampleNavigation(title: title)

        case .prefetchPagination:
            READMEPrefetchPaginationViewController()
                .toSwiftUI()
                .readmeExampleNavigation(title: title)

        case .swiftUIBridge:
            READMESwiftUIBridgeView()
                .readmeExampleNavigation(title: title)
        }
    }
}

/// 캡처 시 지정한 예제로 바로 이동하면서 실제 Demo와 같은 back button을
/// 유지합니다.
struct READMEExampleCaptureRootView: View {
    @State private var path: [READMEExampleRoute]

    init(route: READMEExampleRoute) {
        _path = State(initialValue: [route])
    }

    var body: some View {
        NavigationStack(path: $path) {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
                .navigationDestination(
                    for: READMEExampleRoute.self
                ) { route in
                    route.destination
                }
        }
        .tint(.yellow)
    }
}

private extension View {
    func readmeExampleNavigation(
        title: String
    ) -> some View {
        navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
    }
}
