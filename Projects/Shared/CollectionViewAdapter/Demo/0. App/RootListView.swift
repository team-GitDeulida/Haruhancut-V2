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
                            accounts: BankAccount.sample
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
                            accounts: BankAccount.sample
                        )
                        .toSwiftUI()
                    } label: {
                        CustomLabel(
                            title: "Compositional Layout",
                            caption: "기본 예시와 같은 화면을 Compositional Layout으로 구현합니다",
                            shape: .purple
                        )
                    }

                    NavigationLink {
                        DiffableAccountListViewController(
                            accounts: BankAccount.sample
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
                            accounts: BankAccount.sample
                        )
                        .toSwiftUI()
                    } label: {
                        CustomLabel(
                            title: "DifferenceKit",
                            caption: "커스텀 diffing으로 변경된 계좌 항목만 갱신합니다",
                            shape: .teal
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

                Section("Next Examples") {
                    Text("새 예제는 NavigationLink를 추가해 확장할 수 있습니다.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Adapter Demo")
        }
        .tint(.yellow)
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
