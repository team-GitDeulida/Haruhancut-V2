import CollectionViewAdapter
import UIKit

/// 계좌와 설정 행을 같은 UIView로 표현하는 Component입니다.
struct ComponentDemoRowComponent: Component {
    typealias Item = ComponentDemoRowContentView.Item

    let item: Item

    var estimatedHeight: CGFloat {
        item.subtitle == nil ? 72 : 84
    }

    func createContent() -> ComponentDemoRowContentView {
        ComponentDemoRowContentView()
    }

    func render(
        context _: ComponentContext,
        content: ComponentDemoRowContentView
    ) {
        content.item = item
    }
}
