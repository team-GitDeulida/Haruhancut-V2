import CollectionViewAdapter
import UIKit

/// 고정 header와 화면 거리 기반 무한 스크롤을 조합한 예제입니다.
@MainActor
final class PinnedHeaderInfiniteScrollViewController:
    UIViewController
{
    private enum Constant {
        static let pageSize = 20
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
        collectionView.translatesAutoresizingMaskIntoConstraints =
            false
        return collectionView
    }()

    private lazy var adapter: CollectionViewAdapter = {
        let adapter = CollectionViewAdapter(
            collectionView: collectionView
        )
        adapter.reachedEndThreshold =
            .relativeToViewport(1.5)
        adapter.reachedEnd = { [weak self] in
            self?.loadNextPageIfNeeded()
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
                subtitle: "끝에서 화면 높이의 1.5배 전에 다음 페이지를 불러옵니다.",
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
