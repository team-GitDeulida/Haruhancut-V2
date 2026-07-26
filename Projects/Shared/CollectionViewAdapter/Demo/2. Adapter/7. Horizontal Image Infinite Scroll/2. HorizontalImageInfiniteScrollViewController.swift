import CollectionViewAdapter
import UIKit

/// 가로 CollectionView에서 이미지 prefetch와 pagination을 함께
/// 사용하는 예제입니다.
@MainActor
final class HorizontalImageInfiniteScrollViewController:
    UIViewController
{
    private enum Constant {
        static let sectionIdentifier =
            "horizontal-image-infinite-feed"
        static let pageSize = 12
        static let simulatedNetworkDelay:
            Duration = .milliseconds(650)
        static let cardWidth: CGFloat = 300
        static let cardHeight: CGFloat = 320
    }

    private let layoutAdapter =
        CollectionViewLayoutAdapter()
    private let imageLoader =
        ImageInfiniteScrollImageLoader()
    private var items:
        [HorizontalImageInfiniteScrollContentView.Item] = []
    private var itemsByID:
        [
            Int:
                HorizontalImageInfiniteScrollContentView.Item
        ] = [:]
    private var nextPage = 1
    private var isLoadingNextPage = false
    private var loadingTask: Task<Void, Never>?

    private let descriptionLabel = UILabel()
    private let countLabel = UILabel()
    private let activityIndicator = UIActivityIndicatorView(
        style: .medium
    )
    private let statusStackView = UIStackView()

    private lazy var sectionLayout =
        CollectionSectionLayout { _ in
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .fractionalHeight(1)
            )
            let item = NSCollectionLayoutItem(
                layoutSize: itemSize
            )
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .absolute(
                    Constant.cardWidth
                ),
                heightDimension: .absolute(
                    Constant.cardHeight
                )
            )
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: groupSize,
                subitems: [item]
            )
            let section = NSCollectionLayoutSection(
                group: group
            )
            section.interGroupSpacing = 12
            section.contentInsets =
                NSDirectionalEdgeInsets(
                    top: 16,
                    leading: 20,
                    bottom: 16,
                    trailing: 20
                )
            return section
        }

    private lazy var collectionView: UICollectionView = {
        let configuration =
            UICollectionViewCompositionalLayoutConfiguration()
        configuration.scrollDirection = .horizontal

        let layout = UICollectionViewCompositionalLayout(
            sectionProvider: layoutAdapter.sectionLayout,
            configuration: configuration
        )
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: layout
        )
        collectionView.backgroundColor =
            .systemGroupedBackground
        collectionView.alwaysBounceHorizontal = true
        collectionView.isPrefetchingEnabled = true
        collectionView.decelerationRate = .fast
        collectionView.translatesAutoresizingMaskIntoConstraints =
            false
        return collectionView
    }()

    private lazy var adapter:
        CollectionViewAdapter = {
            let adapter = CollectionViewAdapter(
                collectionView: collectionView,
                layoutAdapter: layoutAdapter
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
                    HorizontalImageInfiniteScrollComponent(
                        item: item,
                        imageLoader: self.imageLoader
                    )
                }
            }
            .withSectionLayout(sectionLayout)
        }
    }

    deinit {
        loadingTask?.cancel()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        appendPage(0)
        updateStatus()
        render(animatingDifferences: false)
    }

    private func configureView() {
        title = "Horizontal Image Infinite Scroll"
        view.backgroundColor = .systemGroupedBackground

        descriptionLabel.text =
            "가로 스크롤 · 이미지 prefetch · 1.5배 선행 pagination"
        descriptionLabel.font = .preferredFont(
            forTextStyle: .subheadline
        )
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.adjustsFontForContentSizeCategory =
            true

        countLabel.font = .preferredFont(
            forTextStyle: .footnote
        )
        countLabel.textColor = .secondaryLabel
        countLabel.adjustsFontForContentSizeCategory = true

        activityIndicator.color = .secondaryLabel
        activityIndicator.hidesWhenStopped = true

        statusStackView.axis = .horizontal
        statusStackView.alignment = .center
        statusStackView.spacing = 8
        statusStackView.addArrangedSubview(countLabel)
        statusStackView.addArrangedSubview(
            activityIndicator
        )

        descriptionLabel.translatesAutoresizingMaskIntoConstraints =
            false
        statusStackView.translatesAutoresizingMaskIntoConstraints =
            false

        view.addSubview(descriptionLabel)
        view.addSubview(statusStackView)
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            descriptionLabel.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 20
            ),
            descriptionLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: view.trailingAnchor,
                constant: -20
            ),
            descriptionLabel.topAnchor.constraint(
                equalTo:
                    view.safeAreaLayoutGuide.topAnchor,
                constant: 16
            ),

            statusStackView.leadingAnchor.constraint(
                equalTo: descriptionLabel.leadingAnchor
            ),
            statusStackView.topAnchor.constraint(
                equalTo: descriptionLabel.bottomAnchor,
                constant: 6
            ),

            collectionView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),
            collectionView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            ),
            collectionView.topAnchor.constraint(
                equalTo: statusStackView.bottomAnchor,
                constant: 12
            ),
            collectionView.heightAnchor.constraint(
                equalToConstant:
                    Constant.cardHeight + 32
            ),
            collectionView.bottomAnchor.constraint(
                lessThanOrEqualTo:
                    view.safeAreaLayoutGuide.bottomAnchor,
                constant: -16
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
        updateStatus()

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
            updateStatus()
            render(animatingDifferences: false)
        }
    }

    private func appendPage(_ page: Int) {
        let firstID = page * Constant.pageSize
        let newItems = (0..<Constant.pageSize).map {
            offset in
            let id = firstID + offset
            return HorizontalImageInfiniteScrollContentView
                .Item(
                    id: id,
                    title: "가로 사진 \(id + 1)",
                    subtitle:
                        "가로 방향에서도 다음 카드 이미지를 미리 준비합니다.",
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
                "https://picsum.photos/seed/haruhancut-horizontal-\(id)/600/400"
        )!
    }

    private func updateStatus() {
        countLabel.text = isLoadingNextPage
            ? "\(items.count)개 · 다음 페이지 불러오는 중"
            : "\(items.count)개 · 오른쪽으로 스크롤하세요"

        if isLoadingNextPage {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
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
            HorizontalImageInfiniteScrollViewController()
    )
}
