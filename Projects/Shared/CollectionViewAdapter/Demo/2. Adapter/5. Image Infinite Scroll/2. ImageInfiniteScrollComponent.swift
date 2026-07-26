import CollectionViewAdapter
import UIKit

/// 이미지 Item과 공유 이미지 로더를 Content에 연결합니다.
struct ImageInfiniteScrollComponent: Component {
    typealias Item = ImageInfiniteScrollContentView.Item

    let item: Item
    let imageLoader: ImageInfiniteScrollImageLoader

    var estimatedHeight: CGFloat {
        108
    }

    func createContent() -> ImageInfiniteScrollContentView {
        ImageInfiniteScrollContentView(
            imageLoader: imageLoader
        )
    }

    func render(
        context _: ComponentContext,
        content: ImageInfiniteScrollContentView
    ) {
        content.item = item
    }
}
