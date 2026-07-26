import CollectionViewAdapter
import UIKit

/// 고정 section header와 prefetch 기반 무한 스크롤을 조합한 예제입니다.
@MainActor
final class PinnedHeaderInfiniteScrollViewController:
    UIViewController,
    UICollectionViewDataSourcePrefetching
{
    private enum Constant {
        static let pageSize = 20
        static let prefetchThreshold = 5
        static let simulatedNetworkDelay:
            Duration = .milliseconds(650)
    }

    private var items: [InfiniteScrollRowContentView.Item] = []
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
        collectionView.prefetchDataSource = self
        collectionView.translatesAutoresizingMaskIntoConstraints =
            false
        return collectionView
    }()

    private lazy var adapter: CollectionViewAdapter = {
        let adapter = CollectionViewAdapter(
            collectionView: collectionView
        )
        adapter.willDisplayItem = {
            [weak self] _, _, indexPath in
            self?.loadNextPageIfNeeded(
                approachingItemAt: indexPath.item
            )
        }
        return adapter
    }()

    private var sections: SectionModels {
        SectionModels {
            LazySection(identifier: "infinite-feed") {
                For(of: self.items) { item in
                    InfiniteScrollRowComponent(item: item)
                }
            }
            .withHeader(
                InfiniteScrollHeaderComponent(
                    item: .init(
                        id: "infinite-feed-header",
                        title: "무한 피드",
                        loadedCount: self.items.count
                    )
                ),
                height: .absolute(68),
                zIndex: 1
            )
            .withFooter(
                InfiniteScrollFooterComponent(
                    item: .init(
                        id: "infinite-feed-footer",
                        isLoading: self.isLoadingNextPage
                    )
                ),
                height: .absolute(64)
            )
            .withSectionLayout(
                CollectionSectionLayout
                    .verticalList(
                        estimatedRowHeight: 72
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

    func collectionView(
        _ collectionView: UICollectionView,
        prefetchItemsAt indexPaths: [IndexPath]
    ) {
        guard let furthestItem = indexPaths.map(\.item).max()
        else {
            return
        }

        loadNextPageIfNeeded(
            approachingItemAt: furthestItem
        )
    }

    private func configureView() {
        title = "Pinned Header + Infinite Scroll"
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

    private func loadNextPageIfNeeded(
        approachingItemAt itemIndex: Int
    ) {
        guard
            itemIndex >=
                items.count - Constant.prefetchThreshold,
            !isLoadingNextPage
        else {
            return
        }

        isLoadingNextPage = true
        render(animatingDifferences: false)

        let page = nextPage
        loadingTask = Task { [weak self] in
            try? await Task.sleep(
                for: Constant.simulatedNetworkDelay
            )
            guard !Task.isCancelled, let self else {
                return
            }

            appendPage(page)
            nextPage += 1
            isLoadingNextPage = false
            render()
        }
    }

    private func appendPage(_ page: Int) {
        let firstID = page * Constant.pageSize
        let newItems = (0..<Constant.pageSize).map { offset in
            let id = firstID + offset
            return InfiniteScrollRowContentView.Item(
                id: id,
                title: "피드 아이템 \(id + 1)",
                subtitle: "마지막 5개 셀에 접근하면 다음 페이지를 불러옵니다.",
                page: page + 1
            )
        }
        items.append(contentsOf: newItems)
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
            PinnedHeaderInfiniteScrollViewController()
    )
}
