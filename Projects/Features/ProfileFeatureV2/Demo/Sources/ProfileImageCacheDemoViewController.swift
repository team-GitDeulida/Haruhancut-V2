import Kingfisher
import ProfileFeatureV2
import UIKit

/// 프로필 그리드의 다운샘플링, 프리패치, 메모리/디스크 캐시를 손으로 검증하는 데모입니다.
///
/// Picsum의 seed URL을 사용하므로 페이지마다 서로 다른 원본 이미지를 요청하면서도,
/// 다시 같은 페이지를 열면 같은 이미지로 캐시 동작을 확인할 수 있습니다.
final class ProfileImageCacheDemoViewController:
    UIViewController
{
    private enum Constant {
        static let columnCount = 3
        static let itemSpacing: CGFloat = 1
        static let pageSize = 24
        static let paginationThreshold = 9
    }

    private let imagePrefetchSession =
        ProfileGridImagePrefetchSession()
    private var items: [ProfileImageCacheDemoItem] = []
    private var nextPage = 0
    private var isAppendingPage = false
    private var lastTargetWidth: CGFloat = 0

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: makeLayout()
        )
        collectionView.backgroundColor = .systemBackground
        collectionView.alwaysBounceVertical = true
        collectionView.isPrefetchingEnabled = true
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.prefetchDataSource = self
        collectionView.register(
            ImageCell.self,
            forCellWithReuseIdentifier: ImageCell.reuseIdentifier
        )
        return collectionView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "이미지 캐시 실험"
        view.backgroundColor = .systemBackground
        configureCollectionView()
        configureNavigationItems()
        appendNextPage()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let targetWidth = gridItemWidth
        guard abs(lastTargetWidth - targetWidth) > 0.5 else {
            return
        }

        lastTargetWidth = targetWidth
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.reloadData()
    }

    deinit {
        imagePrefetchSession.stop()
    }

    private func configureCollectionView() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor
            ),
            collectionView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),
            collectionView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            ),
            collectionView.bottomAnchor.constraint(
                equalTo: view.bottomAnchor
            ),
        ])
    }

    private func configureNavigationItems() {
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(
                title: "디스크",
                style: .plain,
                target: self,
                action: #selector(clearDiskCache)
            ),
            UIBarButtonItem(
                title: "메모리",
                style: .plain,
                target: self,
                action: #selector(clearMemoryCache)
            ),
        ]
        navigationItem.prompt =
            "Picsum 무한 스크롤 · 프리패치 6개/동시 1개"
    }

    private func appendNextPage() {
        guard !isAppendingPage else {
            return
        }

        isAppendingPage = true
        let page = nextPage
        let newItems = (0..<Constant.pageSize).map {
            index in
            let id = "profile-cache-demo-\(page)-\(index)"
            return ProfileImageCacheDemoItem(
                id: id,
                imageURL: URL(
                    string:
                        "https://picsum.photos/seed/\(id)/1200/1800"
                )!
            )
        }
        let startIndex = items.count
        items.append(
            contentsOf: newItems
        )
        nextPage += 1
        isAppendingPage = false

        collectionView.performBatchUpdates {
            collectionView.insertItems(
                at: newItems.indices.map {
                    IndexPath(
                        item: startIndex + $0,
                        section: 0
                    )
                }
            )
        }
    }

    private func appendNextPageIfNeeded(
        for itemIndex: Int
    ) {
        guard itemIndex >= items.count - Constant.paginationThreshold else {
            return
        }
        appendNextPage()
    }

    private var gridItemWidth: CGFloat {
        let availableWidth = max(
            collectionView.bounds.width,
            1
        )
        let totalSpacing = CGFloat(
            Constant.columnCount - 1
        ) * Constant.itemSpacing
        return max(
            (availableWidth - totalSpacing)
                / CGFloat(Constant.columnCount),
            1
        )
    }

    private func makeLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout {
            [weak self] _, _ in
            let targetWidth = self?.gridItemWidth ?? 1
            let item = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .fractionalHeight(1)
                )
            )
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .absolute(targetWidth * 1.5)
                ),
                repeatingSubitem: item,
                count: Constant.columnCount
            )
            group.interItemSpacing = .fixed(
                Constant.itemSpacing
            )

            let section = NSCollectionLayoutSection(
                group: group
            )
            section.interGroupSpacing = Constant.itemSpacing
            return section
        }
    }

    @objc
    private func clearMemoryCache() {
        ImageCache.default.clearMemoryCache()
        imagePrefetchSession.stop()
        collectionView.reloadData()
        navigationItem.prompt = "메모리 캐시를 비웠습니다"
    }

    @objc
    private func clearDiskCache() {
        imagePrefetchSession.stop()
        ImageCache.default.clearDiskCache {
            [weak self] in
            Task { @MainActor [weak self] in
                self?.collectionView.reloadData()
                self?.navigationItem.prompt =
                    "디스크 캐시를 비웠습니다"
            }
        }
    }
}

extension ProfileImageCacheDemoViewController:
    UICollectionViewDataSource
{
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        items.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ImageCell.reuseIdentifier,
                for: indexPath
            ) as? ImageCell
        else {
            return UICollectionViewCell()
        }

        cell.configure(
            item: items[indexPath.item],
            targetWidth: gridItemWidth
        )
        return cell
    }
}

extension ProfileImageCacheDemoViewController:
    UICollectionViewDelegate
{
    func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        appendNextPageIfNeeded(
            for: indexPath.item
        )
    }
}

extension ProfileImageCacheDemoViewController:
    UICollectionViewDataSourcePrefetching
{
    func collectionView(
        _ collectionView: UICollectionView,
        prefetchItemsAt indexPaths: [IndexPath]
    ) {
        let requests: [ProfileGridImagePrefetchRequest] = indexPaths.compactMap {
            indexPath in
            guard items.indices.contains(indexPath.item) else {
                return nil
            }
            let item = items[indexPath.item]
            return ProfileGridImagePrefetchRequest(
                postID: item.id,
                imageURL: item.imageURL
            )
        }
        imagePrefetchSession.prefetch(
            requests,
            targetWidth: gridItemWidth
        )

        if let furthestIndex = indexPaths.map(\.item).max() {
            appendNextPageIfNeeded(
                for: furthestIndex
            )
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cancelPrefetchingForItemsAt indexPaths: [IndexPath]
    ) {
        let postIDs: [String] = indexPaths.compactMap {
            indexPath in
            guard items.indices.contains(indexPath.item) else {
                return nil
            }
            return items[indexPath.item].id
        }
        imagePrefetchSession.cancelPrefetching(
            postIDs: postIDs
        )
    }
}

private final class ImageCell: UICollectionViewCell {
    static let reuseIdentifier = "profile-image-cache-demo-cell"

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray5
        return imageView
    }()

    override init(
        frame: CGRect
    ) {
        super.init(frame: frame)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(
                equalTo: contentView.topAnchor
            ),
            imageView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor
            ),
            imageView.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor
            ),
            imageView.bottomAnchor.constraint(
                equalTo: contentView.bottomAnchor
            ),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:)는 지원하지 않습니다.")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.kf.cancelDownloadTask()
        imageView.image = nil
    }

    func configure(
        item: ProfileImageCacheDemoItem,
        targetWidth: CGFloat
    ) {
        imageView.kf.setImage(
            with: item.imageURL,
            options: ProfileGridImageRequest.options(
                targetWidth: targetWidth
            )
        )
    }
}

private struct ProfileImageCacheDemoItem: Hashable {
    let id: String
    let imageURL: URL
}
