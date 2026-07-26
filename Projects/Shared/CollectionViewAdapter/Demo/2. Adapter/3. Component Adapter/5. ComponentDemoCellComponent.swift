import CollectionViewAdapter
import SwiftUI
import UIKit

/// 계좌와 설정 행을 같은 UIView로 표현하는 Component입니다.
///
/// `View`를 함께 채택해 SwiftUI에서는 `ComponentView`로 직접 감싸지 않고
/// Component 자체를 View처럼 사용할 수 있습니다.
struct ComponentDemoRowComponent: Component, View {
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
