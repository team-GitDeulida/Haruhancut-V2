import Kingfisher
import MachO
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
                title: "측정",
                style: .plain,
                target: self,
                action: #selector(observeCacheClearMemory)
            ),
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
        let indexPaths = newItems.indices.map {
            IndexPath(
                item: startIndex + $0,
                section: 0
            )
        }

        collectionView.performBatchUpdates {
            self.items.append(
                contentsOf: newItems
            )
            self.nextPage += 1
            self.collectionView.insertItems(
                at: indexPaths
            )
        } completion: {
            [weak self] _ in
            self?.isAppendingPage = false
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
                    widthDimension: .fractionalWidth(
                        1 / CGFloat(Constant.columnCount)
                    ),
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

    /// 캐시 삭제가 즉시 프로세스 메모리 감소로 이어지지 않는 현상을 관찰합니다.
    ///
    /// 뷰에 표시 중인 이미지, allocator가 유지하는 힙 페이지, OS 메모리 회수 시점은
    /// ImageCache와 별개입니다. 따라서 이 동작은 누수를 판정하지 않고,
    /// 캐시 참조 삭제 전후의 `phys_footprint` 변화를 확인하는 데만 사용합니다.
    @objc
    private func observeCacheClearMemory() {
        let footprintBefore = ProcessMemoryFootprint.current
        imagePrefetchSession.stop()
        ImageCache.default.clearMemoryCache()
        navigationItem.prompt =
            "캐시 삭제 후 메모리를 관찰하고 있습니다"

        ImageCache.default.clearDiskCache {
            [weak self] in
            Task { @MainActor [weak self] in
                guard let self else {
                    return
                }
                let footprintImmediatelyAfter =
                    ProcessMemoryFootprint.current

                DispatchQueue.main.asyncAfter(
                    deadline: .now() + 1
                ) {
                    [weak self] in
                    guard let self else {
                        return
                    }
                    self.presentMemoryObservation(
                        before: footprintBefore,
                        immediatelyAfter:
                            footprintImmediatelyAfter,
                        delayedAfter:
                            ProcessMemoryFootprint.current
                    )
                    self.collectionView.reloadData()
                }
            }
        }
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

    private func presentMemoryObservation(
        before: UInt64,
        immediatelyAfter: UInt64,
        delayedAfter: UInt64
    ) {
        navigationItem.prompt =
            "캐시 삭제 전후 footprint를 확인했습니다"
        let alert = UIAlertController(
            title: "캐시 삭제 메모리 관찰",
            message: [
                "삭제 전: \(before.memoryString)",
                "삭제 직후: \(immediatelyAfter.memoryString)",
                "1초 후: \(delayedAfter.memoryString)",
                "",
                "ImageCache 참조를 지워도 visible 이미지, allocator, OS 회수 시점 때문에 footprint가 바로 줄지 않거나 변동할 수 있습니다.",
            ].joined(separator: "\n"),
            preferredStyle: .alert
        )
        alert.addAction(
            UIAlertAction(
                title: "확인",
                style: .default
            )
        )
        present(
            alert,
            animated: true
        )
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

private enum ProcessMemoryFootprint {
    static var current: UInt64 {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(
            MemoryLayout<task_vm_info_data_t>.stride
                / MemoryLayout<natural_t>.stride
        )
        let result = withUnsafeMutablePointer(
            to: &info
        ) {
            pointer in
            pointer.withMemoryRebound(
                to: integer_t.self,
                capacity: Int(count)
            ) {
                task_info(
                    mach_task_self_,
                    task_flavor_t(TASK_VM_INFO),
                    $0,
                    &count
                )
            }
        }
        guard result == KERN_SUCCESS else {
            return 0
        }
        return info.phys_footprint
    }
}

private extension UInt64 {
    var memoryString: String {
        ByteCountFormatter.string(
            fromByteCount: Int64(self),
            countStyle: .memory
        )
    }
}
