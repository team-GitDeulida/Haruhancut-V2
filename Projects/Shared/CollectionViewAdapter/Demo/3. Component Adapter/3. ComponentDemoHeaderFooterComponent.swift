import CollectionViewAdapter
import UIKit

/// Header와 footer 위치에서 공통으로 재사용하는 Component입니다.
@MainActor
struct ComponentDemoTextComponent: Component {
    struct ContentVersion: Hashable {
        let identifier: AnyHashable
        let text: String
        let style: Style
    }

    enum Style: Hashable {
        case header
        case footer
    }

    let identifier: AnyHashable
    let text: String
    let style: Style

    var contentVersion: AnyHashable {
        AnyHashable(
            ContentVersion(
                identifier: identifier,
                text: text,
                style: style
            )
        )
    }

    var estimatedHeight: CGFloat {
        switch style {
        case .header:
            return 62
        case .footer:
            return 48
        }
    }

    init<ID: Hashable>(
        identifier: ID,
        text: String,
        style: Style
    ) {
        self.identifier = AnyHashable(identifier)
        self.text = text
        self.style = style
    }

    func createContent() -> ComponentDemoTextContentView {
        ComponentDemoTextContentView()
    }

    func render(
        context _: ComponentContext,
        content: ComponentDemoTextContentView
    ) {
        content.configure(
            text: text,
            style: style
        )
    }
}
