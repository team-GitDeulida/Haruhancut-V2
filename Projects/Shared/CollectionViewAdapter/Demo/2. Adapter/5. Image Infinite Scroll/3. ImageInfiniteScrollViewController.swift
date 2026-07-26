import CollectionViewAdapter
import UIKit

/// Item 이미지 prefetch와 화면 거리 기반 pagination을 함께
/// 보여주는 예제입니다.
@MainActor
final class ImageInfiniteScrollViewController:
    UIViewController
{
    private enum Constant {
        static let sectionIdentifier =
            "image-infinite-feed"
        static let pageSize = 16
        static let simulatedNetworkDelay:
            Duration = .milliseconds(650)
    }

    private let imageLoader =
        ImageInfiniteScrollImageLoader()
    private var items:
        [ImageInfiniteScrollContentView.Item] = []
    private var itemsByID:
        [Int: ImageInfiniteScrollContentView.Item] = [:]
    private var nextPage = 1
    private var isLoadingNextPage = false
    private var loadingTask: Task<Void, Never>?

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout:
                UICollectionViewFlowLayout()
        )
        collectionView.backgroundColor = .systemBackground
        collectionView.alwaysBounceVertical = true
        collectionView.isPrefetchingEnabled = true
        collectionView.translatesAutoresizingMaskIntoConstraints =
            false
        return collectionView
    }()

    private lazy var adapter:
        CollectionViewAdapter = {
            let adapter = CollectionViewAdapter(
                collectionView: collectionView
            )

            adapter.prefetchItems = { [weak self] items in
                self?.prefetchImages(for: items)
            }
            adapter.cancelPrefetchingItems = {
                [weak self] items in
                self?.cancelImagePrefetching(for: items)
            }
            adapter.reachedEndThreshold =
                .relativeToViewport(1.5)
            adapter.reachedEnd = { [weak self] in
                self?.loadNextPageIfNeeded()
            }
            return adapter
        }()

    private var sections: SectionModels {
        SectionModels {
            LazySection(
                identifier: Constant.sectionIdentifier
            ) {
                For(of: self.items) { item in
                    ImageInfiniteScrollComponent(
                        item: item,
                        imageLoader: self.imageLoader
                    )
                }
            }
            .withHeader(
                InfiniteScrollHeaderComponent(
                    item: .init(
                        id: "image-infinite-feed-header",
                        title: "Prefetch 사용",
                        loadedCount: self.items.count
                    )
                ),
                height: .absolute(68),
                zIndex: 1
            )
            .withFooter(
                InfiniteScrollFooterComponent(
                    item: .init(
                        id: "image-infinite-feed-footer",
                        isLoading: self.isLoadingNextPage
                    )
                ),
                height: .absolute(64)
            )
            .withSectionLayout(
                CollectionSectionLayout
                    .verticalList(
                        estimatedRowHeight: 108
                    )
                    .withHeaderPinToVisibleBounds(true)
            )
        }
    }

    deinit {
        loadingTask?.cancel()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        appendPage(0)
        render(animatingDifferences: false)
    }

    private func configureView() {
        title = "Image Prefetch + Infinite Scroll"
        view.backgroundColor = .systemBackground
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),
            collectionView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            ),
            collectionView.topAnchor.constraint(
                equalTo: view.topAnchor
            ),
            collectionView.bottomAnchor.constraint(
                equalTo: view.bottomAnchor
            ),
        ])
    }

    private func prefetchImages(
        for prefetchItems: [CollectionViewPrefetchItem]
    ) {
        imageLoader.prefetch(
            imageURLs(for: prefetchItems)
        )
    }

    private func cancelImagePrefetching(
        for prefetchItems: [CollectionViewPrefetchItem]
    ) {
        imageLoader.cancelPrefetching(
            imageURLs(for: prefetchItems)
        )
    }

    private func imageURLs(
        for prefetchItems: [CollectionViewPrefetchItem]
    ) -> [URL] {
        prefetchItems.compactMap { prefetchItem in
            guard
                prefetchItem.sectionIdentifier ==
                    AnyHashable(
                        Constant.sectionIdentifier
                    ),
                let itemID =
                    prefetchItem.itemIdentifier.base
                        as? Int
            else {
                return nil
            }

            return itemsByID[itemID]?.imageURL
        }
    }

    private func loadNextPageIfNeeded() {
        guard !isLoadingNextPage else {
            return
        }

        isLoadingNextPage = true
        render(animatingDifferences: false)

        let page = nextPage
        loadingTask = Task { @MainActor [weak self] in
            try? await Task.sleep(
                for: Constant.simulatedNetworkDelay
            )
            guard !Task.isCancelled, let self else {
                return
            }

            appendPage(page)
            nextPage += 1
            isLoadingNextPage = false
            render(animatingDifferences: false)
        }
    }

    private func appendPage(_ page: Int) {
        let firstID = page * Constant.pageSize
        let newItems = (0..<Constant.pageSize).map {
            offset in
            let id = firstID + offset
            return ImageInfiniteScrollContentView.Item(
                id: id,
                title: "오늘의 사진 \(id + 1)",
                subtitle:
                    "곧 보일 Item의 이미지를 UIKit prefetch로 준비합니다.",
                imageURL: imageURL(for: id),
                page: page + 1
            )
        }

        for item in newItems {
            itemsByID[item.id] = item
        }
        items.append(contentsOf: newItems)
    }

    private func imageURL(for id: Int) -> URL {
        URL(
            string:
                "https://picsum.photos/seed/haruhancut-\(id)/600/400"
        )!
    }

    private func render(
        animatingDifferences: Bool = true
    ) {
        adapter.bind(
            sections,
            animatingDifferences: animatingDifferences
        )
    }
}

#Preview {
    UINavigationController(
        rootViewController:
            ImageInfiniteScrollViewController()
    )
}
