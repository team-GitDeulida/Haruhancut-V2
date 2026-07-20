import SwiftUI

struct DemoHomeView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("UIKit Examples") {
                    NavigationLink {
                        CollectionViewAdapterExampleView()
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("CollectionViewAdapter")
                                    .font(.headline)

                                Text("UIViewController를 SwiftUI에서 실행합니다")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "rectangle.grid.2x2.fill")
                                .foregroundStyle(.yellow)
                        }
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
