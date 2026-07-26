import CollectionViewAdapter
import UIKit

/// Header와 footer 위치에서 공통으로 재사용하는 Component입니다.
struct ComponentDemoTextComponent: Component {
    typealias Item = ComponentDemoTextContentView.Item

    let item: Item

    var estimatedHeight: CGFloat {
        switch item.style {
        case .header:
            return 62
        case .footer:
            return 48
        }
    }

    func createContent() -> ComponentDemoTextContentView {
        ComponentDemoTextContentView()
    }

    func render(
        context _: ComponentContext,
        content: ComponentDemoTextContentView
    ) {
        content.item = item
    }
}
