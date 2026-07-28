import SwiftUI

struct CustomLabel<Style: ShapeStyle>: View {
    let title: String
    let caption: String
    let shape: Style

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(caption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: "rectangle.grid.2x2.fill")
                .foregroundStyle(shape)
        }
    }
}

struct RootListView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("UIKit Examples") {
                    NavigationLink {
                        FlowLayoutAccountListViewController(
                            sections: BankAccountSection.sample
                        )
                        .toSwiftUI()
                    } label: {
                        CustomLabel(
                            title: "FlowLayout",
                            caption: "UICollectionViewFlowLayout 기반 예시입니다",
                            shape: .blue
                        )
                    }

                    NavigationLink {
                        CompositionalAccountListViewController(
                            sections: BankAccountSection.sample
                        )
                        .toSwiftUI()
                    } label: {
                        CustomLabel(
                            title: "Compositional Layout",
                            caption: "UICollectionViewCompositionalLayout 기반 예시입니다",
                            shape: .purple
                        )
                    }

                    NavigationLink {
                        DiffableAccountListViewController(
                            sections: BankAccountSection.sample
                        )
                        .toSwiftUI()
                    } label: {
                        CustomLabel(
                            title: "Compositional + Diffable",
                            caption: "Compositional Layout과 Diffable Data Source를 함께 사용합니다",
                            shape: .indigo
                        )
                    }

                    NavigationLink {
                        DifferenceKitAccountListViewController(
                            sections: BankAccountSection.sample
                        )
                        .toSwiftUI()
                    } label: {
                        CustomLabel(
                            title: "DifferenceKit",
                            caption: "커스텀 diffing으로 변경된 계좌 항목만 갱신합니다",
                            shape: .teal
                        )
                    }

                    NavigationLink {
                        DelegateAccountListViewController(
                            sections: BankAccountSection.sample
                        )
                        .toSwiftUI()
                    } label: {
                        CustomLabel(
                            title: "Delegate Events",
                            caption: "선택, 길게 누르기, 표시 lifecycle delegate를 사용합니다",
                            shape: .pink
                        )
                    }

                    NavigationLink {
                        PrefetchAccountListViewController()
                            .toSwiftUI()
                    } label: {
                        CustomLabel(
                            title: "Prefetching",
                            caption: "곧 표시할 셀의 데이터를 미리 준비하고 취소합니다",
                            shape: .mint
                        )
                    }

                    NavigationLink {
                        ScrollInfiniteAccountListViewController()
                            .toSwiftUI()
                    } label: {
                        CustomLabel(
                            title: "Scroll Infinite",
                            caption: "스크롤 위치가 끝에 가까워지면 다음 페이지를 요청합니다",
                            shape: .orange
                        )
                    }

                    NavigationLink {
                        PrefetchImageInfiniteScrollViewController()
                            .toSwiftUI()
                    } label: {
                        CustomLabel(
                            title: "Prefetch + Scroll",
                            caption: "페이지 요청과 아이템별 이미지 prefetch를 함께 사용합니다",
                            shape: .cyan
                        )
                    }
                }

                Section("Component") {
                    NavigationLink {
                        ComponentCapabilityDemoViewController(kind: .touchable)
                        .toSwiftUI()
                    } label: {
                        CustomLabel(
                            title: "Touchable",
                            caption: "Content 전체의 탭 이벤트를 modifier로 연결합니다",
                            shape: .blue
                        )
                    }

                    NavigationLink {
                        ComponentCapabilityDemoViewController(kind: .pressable)
                        .toSwiftUI()
                    } label: {
                        CustomLabel(
                            title: "Pressable",
                            caption: "누르는 동안 Content에 축소 효과를 적용합니다",
                            shape: .indigo
                        )
                    }

                    NavigationLink {
                        ComponentCapabilityDemoViewController(kind: .longPressable)
                        .toSwiftUI()
                    } label: {
                        CustomLabel(
                            title: "LongPressable",
                            caption: "Content 전체의 길게 누르기 이벤트를 modifier로 연결합니다",
                            shape: .purple
                        )
                    }

                    NavigationLink {
                        ComponentCapabilityDemoViewController(kind: .containsButton)
                        .toSwiftUI()
                    } label: {
                        CustomLabel(
                            title: "ContainsButton",
                            caption: "Content 내부 버튼 이벤트를 modifier로 전달합니다",
                            shape: .orange
                        )
                    }

                    NavigationLink {
                        ComponentCapabilityDemoViewController(kind: .containsSwitch)
                        .toSwiftUI()
                    } label: {
                        CustomLabel(
                            title: "ContainsSwitch",
                            caption: "Content 내부 스위치의 변경 값을 전달합니다",
                            shape: .green
                        )
                    }
                }

                Section("CollectionView") {

                    NavigationLink {
                        CollectionViewAdapterExampleView()
                    } label: {
                        CustomLabel(
                            title: "FlowCollectionViewAdapter",
                            caption: "외부에서 셀의 타입을 요구합니다",
                            shape: .yellow
                        )
                    }

                    NavigationLink {
                        AdapterAccountListViewController(accounts: BankAccount.sample).toSwiftUI()
                    } label: {
                        CustomLabel(
                            title: "First CollectionViewAdapter",
                            caption: "외부에서 셀의 타입을 요구하지 않습니다",
                            shape: .green
                        )
                    }

                    NavigationLink {
                        ComponentAdapterDemoViewController()
                            .toSwiftUI()
                    } label: {
                        CustomLabel(
                            title: "Component Adapter",
                            caption: "Section DSL과 Compositional Layout 예제입니다",
                            shape: .orange
                        )
                    }

                    NavigationLink {
                        PinnedHeaderInfiniteScrollViewController()
                            .toSwiftUI()
                    } label: {
                        CustomLabel(
                            title: "Pinned Header + Infinite Scroll",
                            caption: "고정 헤더와 페이지 단위 무한 스크롤 예제입니다",
                            shape: .yellow
                        )
                    }

                    NavigationLink {
                        ImageInfiniteScrollViewController()
                            .toSwiftUI()
                    } label: {
                        CustomLabel(
                            title: "Image Prefetch + Infinite Scroll",
                            caption: "이미지 prefetch와 다음 페이지 로딩을 함께 사용합니다",
                            shape: .yellow
                        )
                    }

                    NavigationLink {
                        ImageWithoutPrefetchInfiniteScrollViewController()
                            .toSwiftUI()
                    } label: {
                        CustomLabel(
                            title: "Image Loading + Infinite Scroll",
                            caption: "prefetch 없이 표시 시점에 이미지를 요청합니다",
                            shape: .yellow
                        )
                    }

                    NavigationLink {
                        HorizontalImageInfiniteScrollViewController()
                            .toSwiftUI()
                    } label: {
                        CustomLabel(
                            title: "Section Infinite Scroll",
                            caption: "가로·세로 Section의 독립 pagination을 비교합니다",
                            shape: .yellow
                        )
                    }

                    NavigationLink {
                        GridDemoViewController()
                            .toSwiftUI()
                            .navigationTitle("Grid Layout")
                            .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        CustomLabel(
                            title: "Grid Layout",
                            caption: "2열 카드와 Item 상태 갱신 예제입니다",
                            shape: .yellow
                        )
                    }
                }

                Section("SwiftUI") {
                    NavigationLink {
                        SwiftUIComponentListView()
                    } label: {
                        CustomLabel(
                            title: "Components in SwiftUI List",
                            caption: "기존 Component를 SwiftUI 기본 List에서 재사용합니다",
                            shape: .yellow
                        )
                    }
                }

                ReadmeCaptureSection()
            }
            .navigationTitle("Adapter Demo")
        }
        .tint(.yellow)
    }
}

private struct ReadmeCaptureSection: View {
    var body: some View {
        Section("ReadmeCapture") {
            ForEach(
                ReadmeCaptureRoute.allCases,
                id: \.self
            ) { route in
                NavigationLink {
                    route.destination
                } label: {
                    CustomLabel(
                        title: route.title,
                        caption: route.caption,
                        shape: route.tint
                    )
                }
            }
        }

    }
}

private struct CollectionViewAdapterExampleView: View {
    @State private var viewController = FlowViewController()

    var body: some View {
        viewController
            .toSwiftUI()
            .navigationTitle("CollectionViewAdapter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewController.appendDemoItem()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add snapshot item")
                }
            }
    }
}
