import CollectionViewAdapter
import UIKit

/// 한 CollectionView에서 가로와 세로 Section의 독립 pagination을
/// 함께 사용하는 예제입니다.
@MainActor
final class HorizontalImageInfiniteScrollViewController:
    UIViewController
{
    private enum Constant {
        static let horizontalSectionIdentifier =
            "horizontal-image-infinite-feed"
        static let verticalSectionIdentifier =
            "vertical-image-infinite-feed"
        static let horizontalPageSize = 12
        static let verticalPageSize = 16
        static let simulatedNetworkDelay:
            Duration = .milliseconds(650)
        static let cardHeight: CGFloat = 320
    }

    private let imageLoader =
        ImageInfiniteScrollImageLoader()
    private var horizontalItems:
        [HorizontalImageInfiniteScrollContentView.Item] = []
    private var horizontalItemsByID:
        [
            Int:
                HorizontalImageInfiniteScrollContentView.Item
        ] = [:]
    private var verticalItems:
        [ImageInfiniteScrollContentView.Item] = []
    private var verticalItemsByID:
        [Int: ImageInfiniteScrollContentView.Item] = [:]

    private var nextHorizontalPage = 1
    private var nextVerticalPage = 1
    private var isLoadingHorizontalPage = false
    private var isLoadingVerticalPage = false
    private var horizontalLoadingTask:
        Task<Void, Never>?
    private var verticalLoadingTask:
        Task<Void, Never>?

    private let descriptionLabel = UILabel()
    private let countLabel = UILabel()
    private let activityIndicator = UIActivityIndicatorView(
        style: .medium
    )
    private let statusStackView = UIStackView()

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout:
                UICollectionViewFlowLayout()
        )
        collectionView.backgroundColor =
            .systemGroupedBackground
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
                self?.loadNextVerticalPageIfNeeded()
            }
            return adapter
        }()

    private var sections: SectionModels {
        SectionModels {
            LazySection(
                identifier:
                    Constant.horizontalSectionIdentifier
            ) {
                For(of: self.horizontalItems) { item in
                    HorizontalImageInfiniteScrollComponent(
                        item: item,
                        imageLoader: self.imageLoader
                    )
                }
            }
            .withHeader(
                MixedDirectionSectionHeaderComponent(
                    item: .init(
                        id: "horizontal-section-header",
                        title: "1. 가로 Carousel",
                        description:
                            "Section onReachedEnd로 오른쪽 페이지를 추가합니다.",
                        loadedCount:
                            self.horizontalItems.count,
                        isLoading:
                            self.isLoadingHorizontalPage,
                        contentHorizontalInset: 0
                    )
                ),
                height: .absolute(72)
            )
            .withSectionLayout(
                .horizontalCarousel(
                    itemWidth: 0.76,
                    estimatedHeight:
                        Constant.cardHeight,
                    spacing: 12,
                    behavior: .continuous,
                    contentInsets:
                        NSDirectionalEdgeInsets(
                            top: 16,
                            leading: 20,
                            bottom: 16,
                            trailing: 20
                        )
                )
            )
            .onReachedEnd(
                threshold:
                    .relativeToViewport(1.5)
            ) { [weak self] in
                self?.loadNextHorizontalPageIfNeeded()
            }

            LazySection(
                identifier:
                    Constant.verticalSectionIdentifier
            ) {
                For(of: self.verticalItems) { item in
                    ImageInfiniteScrollComponent(
                        item: item,
                        imageLoader: self.imageLoader
                    )
                }
            }
            .withHeader(
                MixedDirectionSectionHeaderComponent(
                    item: .init(
                        id: "vertical-section-header",
                        title: "2. 세로 List",
                        description:
                            "Adapter reachedEnd로 아래쪽 페이지를 추가합니다.",
                        loadedCount:
                            self.verticalItems.count,
                        isLoading:
                            self.isLoadingVerticalPage,
                        contentHorizontalInset: 20
                    )
                ),
                height: .absolute(72)
            )
            .withSectionLayout(
                .verticalList(
                    estimatedRowHeight: 108
                )
            )
        }
    }

    deinit {
        horizontalLoadingTask?.cancel()
        verticalLoadingTask?.cancel()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        appendHorizontalPage(0)
        appendVerticalPage(0)
        updateStatus()
        render(animatingDifferences: false)
    }

    private func configureView() {
        title = "Section Infinite Scroll"
        view.backgroundColor = .systemGroupedBackground

        descriptionLabel.text =
            "가로·세로 Section · 독립 pagination · 이미지 prefetch"
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
                let itemID =
                    prefetchItem.itemIdentifier.base
                        as? Int
            else {
                return nil
            }

            if prefetchItem.sectionIdentifier ==
                AnyHashable(
                    Constant.horizontalSectionIdentifier
                )
            {
                return horizontalItemsByID[itemID]?
                    .imageURL
            }

            if prefetchItem.sectionIdentifier ==
                AnyHashable(
                    Constant.verticalSectionIdentifier
                )
            {
                return verticalItemsByID[itemID]?
                    .imageURL
            }

            return nil
        }
    }

    private func loadNextHorizontalPageIfNeeded() {
        guard !isLoadingHorizontalPage else {
            return
        }

        isLoadingHorizontalPage = true
        updateStatus()
        render(animatingDifferences: false)

        let page = nextHorizontalPage
        horizontalLoadingTask = Task { @MainActor [weak self] in
            try? await Task.sleep(
                for: Constant.simulatedNetworkDelay
            )
            guard !Task.isCancelled, let self else {
                return
            }

            appendHorizontalPage(page)
            nextHorizontalPage += 1
            isLoadingHorizontalPage = false
            horizontalLoadingTask = nil
            updateStatus()
            render(animatingDifferences: false)
        }
    }

    private func loadNextVerticalPageIfNeeded() {
        guard !isLoadingVerticalPage else {
            return
        }

        isLoadingVerticalPage = true
        updateStatus()
        render(animatingDifferences: false)

        let page = nextVerticalPage
        verticalLoadingTask = Task { @MainActor [weak self] in
            try? await Task.sleep(
                for: Constant.simulatedNetworkDelay
            )
            guard !Task.isCancelled, let self else {
                return
            }

            appendVerticalPage(page)
            nextVerticalPage += 1
            isLoadingVerticalPage = false
            verticalLoadingTask = nil
            updateStatus()
            render(animatingDifferences: false)
        }
    }

    private func appendHorizontalPage(_ page: Int) {
        let firstID =
            page * Constant.horizontalPageSize
        let newItems = (
            0..<Constant.horizontalPageSize
        ).map {
            offset in
            let id = firstID + offset
            return HorizontalImageInfiniteScrollContentView
                .Item(
                    id: id,
                    title: "가로 사진 \(id + 1)",
                    subtitle:
                        "가로 방향에서도 다음 카드 이미지를 미리 준비합니다.",
                    imageURL:
                        horizontalImageURL(for: id),
                    page: page + 1
                )
        }

        for item in newItems {
            horizontalItemsByID[item.id] = item
        }
        horizontalItems.append(contentsOf: newItems)
    }

    private func appendVerticalPage(_ page: Int) {
        let firstID =
            page * Constant.verticalPageSize
        let newItems = (
            0..<Constant.verticalPageSize
        ).map {
            offset in
            let id = firstID + offset
            return ImageInfiniteScrollContentView.Item(
                id: id,
                title: "세로 사진 \(id + 1)",
                subtitle:
                    "화면 아래쪽 1.5배 전에 다음 세로 페이지를 요청합니다.",
                imageURL:
                    verticalImageURL(for: id),
                page: page + 1
            )
        }

        for item in newItems {
            verticalItemsByID[item.id] = item
        }
        verticalItems.append(contentsOf: newItems)
    }

    private func horizontalImageURL(
        for id: Int
    ) -> URL {
        URL(
            string:
                "https://picsum.photos/seed/haruhancut-horizontal-\(id)/600/400"
        )!
    }

    private func verticalImageURL(
        for id: Int
    ) -> URL {
        URL(
            string:
                "https://picsum.photos/seed/haruhancut-vertical-\(id)/600/400"
        )!
    }

    private func updateStatus() {
        countLabel.text =
            "가로 \(horizontalItems.count)개 · 세로 \(verticalItems.count)개"

        if isLoadingHorizontalPage ||
            isLoadingVerticalPage
        {
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
