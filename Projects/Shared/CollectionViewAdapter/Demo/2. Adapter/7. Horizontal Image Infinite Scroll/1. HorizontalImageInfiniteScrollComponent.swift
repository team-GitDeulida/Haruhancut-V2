import CollectionViewAdapter
import UIKit

/// 가로 이미지 Item과 공유 이미지 로더를 카드 Content에 연결합니다.
struct HorizontalImageInfiniteScrollComponent: Component {
    typealias Item =
        HorizontalImageInfiniteScrollContentView.Item

    let item: Item
    let imageLoader: ImageInfiniteScrollImageLoader

    var estimatedHeight: CGFloat {
        320
    }

    func createContent()
        -> HorizontalImageInfiniteScrollContentView
    {
        HorizontalImageInfiniteScrollContentView(
            imageLoader: imageLoader
        )
    }

    func render(
        context _: ComponentContext,
        content:
            HorizontalImageInfiniteScrollContentView
    ) {
        content.item = item
    }
}
