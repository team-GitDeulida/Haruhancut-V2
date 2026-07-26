import CollectionViewAdapter
import UIKit

struct InfiniteScrollHeaderComponent: Component {
    typealias Item = InfiniteScrollHeaderContentView.Item

    let item: Item

    var estimatedHeight: CGFloat {
        68
    }

    func createContent() -> InfiniteScrollHeaderContentView {
        InfiniteScrollHeaderContentView()
    }

    func render(
        context _: ComponentContext,
        content: InfiniteScrollHeaderContentView
    ) {
        content.item = item
    }
}

struct InfiniteScrollRowComponent: Component {
    typealias Item = InfiniteScrollRowContentView.Item

    let item: Item

    var estimatedHeight: CGFloat {
        72
    }

    func createContent() -> InfiniteScrollRowContentView {
        InfiniteScrollRowContentView()
    }

    func render(
        context _: ComponentContext,
        content: InfiniteScrollRowContentView
    ) {
        content.item = item
    }
}

struct InfiniteScrollFooterComponent: Component {
    typealias Item = InfiniteScrollFooterContentView.Item

    let item: Item

    var estimatedHeight: CGFloat {
        64
    }

    func createContent() -> InfiniteScrollFooterContentView {
        InfiniteScrollFooterContentView()
    }

    func render(
        context _: ComponentContext,
        content: InfiniteScrollFooterContentView
    ) {
        content.item = item
    }
}
