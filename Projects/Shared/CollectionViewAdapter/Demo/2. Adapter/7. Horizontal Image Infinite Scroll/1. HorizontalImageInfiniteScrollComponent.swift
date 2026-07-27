import CollectionViewAdapter
import UIKit

/// 혼합 방향 Demo의 Section 상태를 header Content에 연결합니다.
struct MixedDirectionSectionHeaderComponent: Component {
    typealias Item =
        MixedDirectionSectionHeaderContentView.Item

    let item: Item

    var estimatedHeight: CGFloat {
        72
    }

    func createContent()
        -> MixedDirectionSectionHeaderContentView
    {
        MixedDirectionSectionHeaderContentView()
    }

    func render(
        context _: ComponentContext,
        content: MixedDirectionSectionHeaderContentView
    ) {
        content.item = item
    }
}

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
