import CollectionViewAdapter
import UIKit

/// 계좌와 설정 행을 같은 UIView로 표현하는 Component입니다.
@MainActor
struct ComponentDemoRowComponent: Component {
    private struct ContentVersion: Hashable {
        let identifier: AnyHashable
        let title: String
        let subtitle: String?
        let symbolName: String
        let accessory: Accessory
        let appearance: Appearance
    }

    enum Accessory: Hashable {
        case button(String)
        case toggle(isOn: Bool)
        case chevron
    }

    enum Appearance: Hashable {
        case connectedCard
        case standaloneCard
    }

    let identifier: AnyHashable
    private var title = ""
    private var subtitle: String?
    private var symbolName = "circle"
    private var accessory: Accessory = .chevron
    private var appearance: Appearance = .standaloneCard

    var contentVersion: AnyHashable {
        AnyHashable(
            ContentVersion(
                identifier: identifier,
                title: title,
                subtitle: subtitle,
                symbolName: symbolName,
                accessory: accessory,
                appearance: appearance
            )
        )
    }

    var estimatedHeight: CGFloat {
        subtitle == nil ? 72 : 84
    }

    init<ID: Hashable>(identifier: ID) {
        self.identifier = AnyHashable(identifier)
    }

    func title(
        _ title: String,
        subtitle: String? = nil
    ) -> Self {
        var copy = self
        copy.title = title
        copy.subtitle = subtitle
        return copy
    }

    func symbol(_ symbolName: String) -> Self {
        var copy = self
        copy.symbolName = symbolName
        return copy
    }

    func accessory(_ accessory: Accessory) -> Self {
        var copy = self
        copy.accessory = accessory
        return copy
    }

    func appearance(_ appearance: Appearance) -> Self {
        var copy = self
        copy.appearance = appearance
        return copy
    }

    func createContent() -> ComponentDemoRowContentView {
        ComponentDemoRowContentView()
    }

    func render(
        context _: ComponentContext,
        content: ComponentDemoRowContentView
    ) {
        content.configure(
            title: title,
            subtitle: subtitle,
            symbolName: symbolName,
            accessory: accessory,
            appearance: appearance
        )
    }
}
