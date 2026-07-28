import SwiftUI

/// `View`를 채택한 UIKit Component를 SwiftUI에서 직접 사용하는 예제입니다.
struct ReadmeSwiftUIComponentView: View {
    @State private var isNotificationEnabled = true
    @State private var selectedAccountName: String?

    private let accounts = Array(
        ComponentDemoAccount.sample.prefix(2)
    )

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                introduction

                ForEach(accounts, id: \.id) { account in
                    ComponentDemoRowComponent(
                        item: .init(
                            id: account.id,
                            title: account.name,
                            subtitle: account.balanceText,
                            symbolName: account.symbolName,
                            accessory: .button("보기"),
                            appearance: .standaloneCard
                        )
                    )
                    .onButtonTap {
                        selectedAccountName = account.name
                    }
                    .frame(height: 84)
                }

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
                .frame(height: 84)
            }
            .padding(.vertical, 24)
        }
        .background(
            Color(
                uiColor: ComponentDemoStyle.background
            )
        )
        .alert(
            "Component Event",
            isPresented: Binding(
                get: { selectedAccountName != nil },
                set: { isPresented in
                    if !isPresented {
                        selectedAccountName = nil
                    }
                }
            )
        ) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(
                "\(selectedAccountName ?? "") Component를 선택했습니다."
            )
        }
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: "swift")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(.pink)
                .frame(width: 58, height: 58)
                .background(
                    Color.pink.opacity(0.12),
                    in: RoundedRectangle(cornerRadius: 18)
                )

            VStack(alignment: .leading, spacing: 6) {
                Text("Component + View")
                    .font(.title2.bold())

                Text(
                    "View를 함께 채택하면 UIKit Component를 SwiftUI 화면에 바로 배치할 수 있습니다."
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 20)
    }
}
