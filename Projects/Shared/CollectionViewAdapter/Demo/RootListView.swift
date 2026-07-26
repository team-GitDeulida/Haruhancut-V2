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
                        CollectionViewAdapterExampleView()
                    } label: {
                        CustomLabel(
                            title: "CollectionViewAdapter",
                            caption: "UIViewController를 SwiftUI에서 실행합니다",
                            shape: .yellow
                        )
                    }
                }
                
                Section("CollectionView") {
                    NavigationLink {
                        AccountListViewController(accounts: BankAccount.sample).toSwiftUI()
                    } label: {
                        CustomLabel(
                            title: "Basic CollectionView",
                            caption: "기초적인 CollectionView 사용법입니다",
                            shape: .blue
                        )
                    }
                    
                    NavigationLink {
                        AdapterAccountListViewController(accounts: BankAccount.sample).toSwiftUI()
                    } label: {
                        CustomLabel(
                            title: "First CollectionViewAdapter",
                            caption: "기초적인 CollectionViewAdapter 사용법입니다",
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
    @State private var viewController = MainViewController()

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
