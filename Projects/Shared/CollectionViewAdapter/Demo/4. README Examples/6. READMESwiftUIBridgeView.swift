import SwiftUI

/// UIKit Component를 SwiftUI 화면의 View처럼 재사용합니다.
struct READMESwiftUIBridgeView: View {
    @State private var isNotificationEnabled = true
    @State private var alertMessage: String?

    private let accounts = ComponentDemoAccount.sample

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("UIKIT COMPONENT")
                        .font(.caption.bold())
                        .foregroundStyle(.pink)

                    Text("같은 Component를\nSwiftUI에서 사용해요")
                        .font(.title2.bold())

                    Text(
                        "UIView의 생성·재사용 규칙은 유지하고 상태와 화면 구조는 SwiftUI가 관리합니다."
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 20)

                ForEach(accounts, id: \.id) { account in
                    ComponentDemoRowComponent(
                        item: .init(
                            id: account.id,
                            title: account.name,
                            subtitle: account.balanceText,
                            symbolName:
                                account.symbolName,
                            accessory: .button("보기"),
                            appearance:
                                .standaloneCard
                        )
                    )
                    .onButtonTap {
                        alertMessage =
                            "\(account.name) · \(account.balanceText)"
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
                            isOn:
                                isNotificationEnabled
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
                uiColor:
                    ComponentDemoStyle.background
            )
        )
        .alert(
            "Component Event",
            isPresented: Binding(
                get: { alertMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        alertMessage = nil
                    }
                }
            )
        ) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(alertMessage ?? "")
        }
    }
}
