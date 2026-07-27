import CollectionViewAdapter
import SwiftUI

/// 기존 UIKit Component를 SwiftUI 기본 `List`에서 재사용하는 예제입니다.
///
/// SwiftUI가 `List`, `Section`, `ForEach`와 화면 상태를 관리하고,
/// `View`를 함께 채택한 Component가 UIKit Content를 행으로 표시합니다.
struct SwiftUIComponentListView: View {
    @State private var isNotificationEnabled = true
    @State private var presentedAlert: ComponentListAlert?

    private let accounts = ComponentDemoAccount.sample

    var body: some View {
        List {
            Section {
                ForEach(accounts, id: \.id) { account in
                    ComponentDemoRowComponent(
                        item: .init(
                            id: account.id,
                            title: account.name,
                            subtitle: account.balanceText,
                            symbolName: account.symbolName,
                            accessory: .button("송금"),
                            appearance: .standaloneCard
                        )
                    )
                    .onTouch {
                        presentedAlert = .init(
                            title: account.name,
                            message:
                                "현재 잔액은 \(account.balanceText)입니다."
                        )
                    }
                    .onButtonTap {
                        presentedAlert = .init(
                            title: "송금",
                            message:
                                "\(account.name)에서 송금을 시작합니다."
                        )
                    }
                    .componentListRow()
                }
            } header: {
                ComponentListSectionHeader(
                    title: "내 계좌",
                    description:
                        "SwiftUI의 ForEach로 UIKit Component를 반복해서 표시합니다.",
                    symbolName: "creditcard.fill"
                )
            }

            Section {
                ComponentDemoRowComponent(
                    item: .init(
                        id: "swiftui-notification",
                        title: "입출금 알림",
                        subtitle:
                            isNotificationEnabled
                            ? "알림이 켜져 있습니다"
                            : "알림이 꺼져 있습니다",
                        symbolName: "bell.fill",
                        accessory: .toggle(
                            isOn: isNotificationEnabled
                        ),
                        appearance: .standaloneCard
                    )
                )
                .onToggle { isOn in
                    isNotificationEnabled = isOn
                }
                .componentListRow()
            } header: {
                ComponentListSectionHeader(
                    title: "설정",
                    description:
                        "Component 이벤트를 SwiftUI 상태와 연결합니다.",
                    symbolName: "slider.horizontal.3"
                )
            }
        }
        .listStyle(.plain)
        .listSectionSpacing(.custom(28))
        .scrollContentBackground(.hidden)
        .contentMargins(.top, 16, for: .scrollContent)
        .contentMargins(.bottom, 32, for: .scrollContent)
        .background(
            Color(
                uiColor:
                    ComponentDemoStyle.background
            )
        )
        .navigationTitle("SwiftUI List")
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $presentedAlert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("확인"))
            )
        }
    }
}

/// SwiftUI List가 관리하는 섹션의 제목과 설명입니다.
private struct ComponentListSectionHeader: View {
    let title: String
    let description: String
    let symbolName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: symbolName)
                .font(.headline)
                .foregroundStyle(
                    Color(
                        uiColor:
                            ComponentDemoStyle.textPrimary
                    )
                )

            Text(description)
                .font(.footnote)
                .foregroundStyle(
                    Color(
                        uiColor:
                            ComponentDemoStyle.textSecondary
                    )
                )
                .fixedSize(horizontal: false, vertical: true)
        }
        .textCase(nil)
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        .listRowInsets(.init())
        .listRowBackground(Color.clear)
    }
}

/// SwiftUI `.alert(item:)`에 전달할 예제 메시지입니다.
private struct ComponentListAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

private extension View {
    /// Component 내부 여백을 유지하면서 SwiftUI List의 기본 행 장식을 제거합니다.
    func componentListRow() -> some View {
        frame(maxWidth: .infinity)
            .padding(.vertical, 5)
            .listRowInsets(.init())
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
}

#Preview {
    NavigationStack {
        SwiftUIComponentListView()
    }
}
