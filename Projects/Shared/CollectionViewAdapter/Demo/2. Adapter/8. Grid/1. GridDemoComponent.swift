import CollectionViewAdapter
import UIKit

/// 사진 주제 Item을 Grid 카드 Content에 연결합니다.
struct GridDemoComponent: Component {
    typealias Item = GridDemoContentView.Item

    let item: Item

    var estimatedHeight: CGFloat {
        178
    }

    func createContent() -> GridDemoContentView {
        GridDemoContentView()
    }

    func render(
        context _: ComponentContext,
        content: GridDemoContentView
    ) {
        content.item = item
    }
}
