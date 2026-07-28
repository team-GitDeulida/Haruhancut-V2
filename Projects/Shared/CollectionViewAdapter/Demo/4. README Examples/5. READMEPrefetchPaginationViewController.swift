import CollectionViewAdapter
import UIKit

/// Prefetch와 scroll threshold 기반 pagination을 안정적인 Item ID로 연결합니다.
@MainActor
final class READMEPrefetchPaginationViewController:
    UIViewController {
    private enum Constant {
        static let pageSize = 14
        static let pageDelay: Duration =
            .milliseconds(450)
    }

    private var items:
        [InfiniteScrollRowContentView.Item] = []
    private var nextPage = 1
    private var isLoading = false
    private var prefetchedIDs: Set<AnyHashable> = []
    private var loadingTask: Task<Void, Never>?

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout:
                UICollectionViewFlowLayout()
        )
        collectionView.backgroundColor = .systemBackground
        collectionView.alwaysBounceVertical = true
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
                self?.prefetchedIDs.formUnion(
                    items.map(\.itemIdentifier)
                )
            }
            adapter.cancelPrefetchingItems = { [weak self] items in
                self?.prefetchedIDs.subtract(
                    items.map(\.itemIdentifier)
                )
            }
            adapter.reachedEndThreshold =
                .relativeToViewport(1.2)
            adapter.reachedEnd = { [weak self] in
                self?.loadNextPage()
            }
            return adapter
        }()

    private var sections: SectionModels {
        SectionModels {
            LazySection(identifier: "photo-feed") {
                For(of: self.items) { item in
                    InfiniteScrollRowComponent(
                        item: item
                    )
                }
            }
            .withHeader(
                InfiniteScrollHeaderComponent(
                    item: .init(
                        id: "photo-feed-header",
                        title:
                            "Prefetch + Pagination",
                        loadedCount: self.items.count
                    )
                ),
                height: .absolute(68),
                zIndex: 1
            )
            .withFooter(
                InfiniteScrollFooterComponent(
                    item: .init(
                        id: "photo-feed-footer",
                        isLoading: self.isLoading
                    )
                ),
                height: .absolute(64)
            )
            .withSectionLayout(
                CollectionSectionLayout
                    .verticalList(
                        estimatedRowHeight: 72
                    )
                    .withHeaderPinToVisibleBounds(
                        true
                    )
            )
        }
    }

    deinit {
        loadingTask?.cancel()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
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
            )
        ])

        appendPage(0)
        render(animatingDifferences: false)
    }

    private func loadNextPage() {
        guard !isLoading else {
            return
        }

        isLoading = true
        render(animatingDifferences: false)
        let page = nextPage

        loadingTask = Task { @MainActor [weak self] in
            try? await Task.sleep(
                for: Constant.pageDelay
            )
            guard !Task.isCancelled, let self else {
                return
            }

            appendPage(page)
            nextPage += 1
            isLoading = false
            render(animatingDifferences: false)
        }
    }

    private func appendPage(_ page: Int) {
        let firstID = page * Constant.pageSize
        let newItems =
            (0..<Constant.pageSize).map { offset in
                let id = firstID + offset
                return InfiniteScrollRowContentView.Item(
                    id: id,
                    title: "오늘의 기록 \(id + 1)",
                    subtitle:
                        "표시 전에 안정적인 ID로 필요한 리소스를 준비합니다.",
                    page: page + 1
                )
            }
        items.append(contentsOf: newItems)
    }

    private func render(
        animatingDifferences: Bool
    ) {
        adapter.bind(
            sections,
            animatingDifferences: animatingDifferences
        )
    }
}
