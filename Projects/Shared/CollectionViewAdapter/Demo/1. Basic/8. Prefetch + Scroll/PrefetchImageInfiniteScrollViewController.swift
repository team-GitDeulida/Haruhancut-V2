//
//  PrefetchImageInfiniteScrollViewController.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/28/26.
//

import UIKit

/**
 동작 흐름

 1. 스크롤 위치가 끝에 가까워지면 다음 이미지 목록 페이지를 요청합니다.
 2. 새 페이지의 Item이 추가되면 UIKit이 곧 보일 이미지의 prefetch를 요청합니다.
 3. ImageInfiniteScrollImageLoader는 prefetch와 화면 표시 요청을 하나의 다운로드 작업으로 합칩니다.
 4. 셀이 실제로 표시되면 캐시된 이미지를 즉시 사용하거나 진행 중인 요청 결과를 받습니다.
 5. UIKit이 prefetch 취소를 전달하면 화면에서 사용 중이지 않은 이미지 요청만 중단합니다.
 */

/// 스크롤 기반 페이지 요청과 UICollectionViewDataSourcePrefetching을 함께 사용하는 이미지 피드입니다.
@MainActor
final class PrefetchImageInfiniteScrollViewController: UIViewController {

    fileprivate struct FeedItem: Hashable {
        let id: Int
        let title: String
        let subtitle: String
        let imageURL: URL
        let page: Int
    }

    private enum Constant {
        static let pageSize = 12
        static let simulatedNetworkDelay: TimeInterval = 0.7
    }

    private let imageLoader = ImageInfiniteScrollImageLoader()
    private var items: [FeedItem] = []
    private var nextPage = 0
    private var isLoadingNextPage = false
    private var loadingWorkItem: DispatchWorkItem?
    private var visibleImageRequestIDs: [Int: UUID] = [:]

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: Self.makeLayout()
        )

        collectionView.backgroundColor = .systemBackground
        collectionView.alwaysBounceVertical = true
        collectionView.isPrefetchingEnabled = true
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.prefetchDataSource = self
        collectionView.register(
            PrefetchImageFeedCollectionViewCell.self,
            forCellWithReuseIdentifier:
                PrefetchImageFeedCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            AccountListSupplementaryView.self,
            forSupplementaryViewOfKind:
                UICollectionView.elementKindSectionHeader,
            withReuseIdentifier:
                AccountListSupplementaryView.reuseIdentifier
        )
        collectionView.register(
            InfiniteScrollFooterView.self,
            forSupplementaryViewOfKind:
                UICollectionView.elementKindSectionFooter,
            withReuseIdentifier:
                InfiniteScrollFooterView.reuseIdentifier
        )

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()

    deinit {
        loadingWorkItem?.cancel()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        appendPage()
        configureNavigation()
        configureLayout()
    }

    private func configureNavigation() {
        title = "Prefetch + Scroll"
        navigationController?
            .navigationBar
            .prefersLargeTitles = true
    }

    private func configureLayout() {
        view.backgroundColor = .systemBackground
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(
                equalTo: view.topAnchor
            ),
            collectionView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),
            collectionView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            ),
            collectionView.bottomAnchor.constraint(
                equalTo: view.bottomAnchor
            )
        ])
    }

    /// 끝에서 viewport 1.5배 거리 안으로 들어오면 다음 이미지 페이지를 요청합니다.
    private func loadNextPageIfNeeded(
        contentOffset: CGPoint
    ) {
        guard !isLoadingNextPage else {
            return
        }

        let viewportLength = collectionView.bounds.height
            - collectionView.adjustedContentInset.top
            - collectionView.adjustedContentInset.bottom
        guard viewportLength > 0 else {
            return
        }

        let visibleEnd = contentOffset.y
            + collectionView.bounds.height
            - collectionView.adjustedContentInset.bottom
        let remainingDistance = collectionView.contentSize.height
            - visibleEnd

        guard remainingDistance <= viewportLength * 1.5 else {
            return
        }

        loadNextPage()
    }

    /// 다음 목록 페이지를 모의 네트워크 응답 뒤에 추가합니다.
    private func loadNextPage() {
        isLoadingNextPage = true
        updateVisibleFooter()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self else {
                return
            }

            self.loadingWorkItem = nil
            self.appendPage()
            self.isLoadingNextPage = false
            self.collectionView.reloadData()
        }
        loadingWorkItem = workItem

        DispatchQueue.main.asyncAfter(
            deadline: .now() + Constant.simulatedNetworkDelay,
            execute: workItem
        )
    }

    /// 다음 페이지의 이미지 피드 Item을 일반 배열에 추가합니다.
    private func appendPage() {
        let page = nextPage
        let firstID = page * Constant.pageSize
        let newItems = (0..<Constant.pageSize).map { offset in
            let id = firstID + offset
            return FeedItem(
                id: id,
                title: "오늘의 사진 " + String(id + 1),
                subtitle: "다음 셀의 이미지는 UIKit prefetch로 미리 준비합니다.",
                imageURL: imageURL(for: id),
                page: page + 1
            )
        }

        items.append(contentsOf: newItems)
        nextPage += 1
    }

    /// 보이는 footer를 바로 갱신해 페이지 요청 중임을 표시합니다.
    private func updateVisibleFooter() {
        collectionView
            .visibleSupplementaryViews(
                ofKind: UICollectionView.elementKindSectionFooter
            )
            .compactMap { $0 as? InfiniteScrollFooterView }
            .forEach { footer in
                footer.configure(
                    isLoading: isLoadingNextPage
                )
            }
    }

    /// 화면에 보이는 셀의 이미지를 요청하고, 셀 재사용을 대비해 Item ID를 검증합니다.
    private func requestImage(
        for item: FeedItem,
        into cell: PrefetchImageFeedCollectionViewCell
    ) {
        guard visibleImageRequestIDs[item.id] == nil else {
            return
        }

        let requestID = imageLoader.requestImage(
            for: item.imageURL
        ) { [weak self, weak cell] image, source in
            self?.visibleImageRequestIDs[item.id] = nil
            cell?.configureImage(
                image,
                source: source,
                itemID: item.id,
                page: item.page
            )
        }

        if let requestID {
            visibleImageRequestIDs[item.id] = requestID
        }
    }

    /// UIKit이 전달한 위치를 이미지 URL 목록으로 변환합니다.
    private func imageURLs(
        for indexPaths: [IndexPath]
    ) -> [URL] {
        indexPaths.compactMap { indexPath in
            guard items.indices.contains(indexPath.item) else {
                return nil
            }
            return items[indexPath.item].imageURL
        }
    }

    private func imageURL(
        for id: Int
    ) -> URL {
        URL(
            string: "https://picsum.photos/seed/basic-prefetch-"
                + String(id)
                + "/600/400"
        )!
    }

    private static func makeLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .absolute(116)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(
            top: 0,
            leading: 20,
            bottom: 0,
            trailing: 20
        )
        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: itemSize,
            subitems: [item]
        )
        let section = NSCollectionLayoutSection(group: group)

        section.interGroupSpacing = 12
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 12,
            leading: 0,
            bottom: 4,
            trailing: 0
        )
        section.boundarySupplementaryItems = [
            Self.makeSupplementaryItem(
                kind: UICollectionView.elementKindSectionHeader,
                height: AccountListSupplementaryView.headerHeight,
                alignment: .top
            ),
            Self.makeSupplementaryItem(
                kind: UICollectionView.elementKindSectionFooter,
                height: InfiniteScrollFooterView.height,
                alignment: .bottom
            )
        ]

        return UICollectionViewCompositionalLayout(section: section)
    }

    private static func makeSupplementaryItem(
        kind: String,
        height: CGFloat,
        alignment: NSRectAlignment
    ) -> NSCollectionLayoutBoundarySupplementaryItem {
        NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .absolute(height)
            ),
            elementKind: kind,
            alignment: alignment
        )
    }
}

// MARK: - UICollectionViewDataSource
/// 일반 배열에 저장된 이미지 피드 Item과 supplementary view를 구성합니다.
extension PrefetchImageInfiniteScrollViewController: UICollectionViewDataSource {

    /// 이미지 피드의 단일 섹션을 반환합니다.
    func numberOfSections(
        in collectionView: UICollectionView
    ) -> Int {
        1
    }

    /// 지금까지 페이지 요청으로 누적된 이미지 Item 수를 반환합니다.
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        items.count
    }

    /// 이미지 요청 전 placeholder 상태의 피드 셀을 구성합니다.
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier:
                PrefetchImageFeedCollectionViewCell.reuseIdentifier,
            for: indexPath
        ) as? PrefetchImageFeedCollectionViewCell else {
            assertionFailure("PrefetchImageFeedCollectionViewCell 생성 실패")
            return UICollectionViewCell()
        }

        cell.configure(item: items[indexPath.item])
        return cell
    }

    /// 헤더에는 결합 예제 설명을, footer에는 페이지 요청 상태를 표시합니다.
    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            guard let header = collectionView
                .dequeueReusableSupplementaryView(
                    ofKind: kind,
                    withReuseIdentifier:
                        AccountListSupplementaryView.reuseIdentifier,
                    for: indexPath
                ) as? AccountListSupplementaryView else {
                assertionFailure("AccountListSupplementaryView 생성 실패")
                return UICollectionReusableView()
            }

            header.configure(
                kind: .header,
                title: "이미지 Prefetch + 페이지 요청",
                description: "다음 페이지와 곧 보일 이미지들을 각각 미리 준비합니다."
            )
            return header

        case UICollectionView.elementKindSectionFooter:
            guard let footer = collectionView
                .dequeueReusableSupplementaryView(
                    ofKind: kind,
                    withReuseIdentifier:
                        InfiniteScrollFooterView.reuseIdentifier,
                    for: indexPath
                ) as? InfiniteScrollFooterView else {
                assertionFailure("InfiniteScrollFooterView 생성 실패")
                return UICollectionReusableView()
            }

            footer.configure(
                isLoading: isLoadingNextPage
            )
            return footer

        default:
            assertionFailure("지원하지 않는 supplementary view kind입니다.")
            return UICollectionReusableView()
        }
    }
}

// MARK: - UICollectionViewDelegate
/// 스크롤 위치와 셀 표시 lifecycle을 이용해 페이지와 표시용 이미지를 요청합니다.
extension PrefetchImageInfiniteScrollViewController: UICollectionViewDelegate {

    /// 현재 스크롤 위치가 threshold 안에 들어오면 다음 페이지를 요청합니다.
    func scrollViewDidScroll(
        _ scrollView: UIScrollView
    ) {
        loadNextPageIfNeeded(contentOffset: scrollView.contentOffset)
    }

    /// 예상 정지 위치를 사용해 빠른 스크롤에서도 다음 페이지를 미리 요청합니다.
    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        loadNextPageIfNeeded(
            contentOffset: targetContentOffset.pointee
        )
    }

    /// 화면에 표시되는 셀이 실제로 사용할 이미지 요청을 연결합니다.
    func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        guard
            let feedCell = cell as? PrefetchImageFeedCollectionViewCell,
            items.indices.contains(indexPath.item)
        else {
            return
        }

        requestImage(
            for: items[indexPath.item],
            into: feedCell
        )
    }

    /// 화면에서 벗어난 셀의 표시용 이미지 요청을 취소합니다.
    func collectionView(
        _ collectionView: UICollectionView,
        didEndDisplaying cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        guard items.indices.contains(indexPath.item) else {
            return
        }

        let itemID = items[indexPath.item].id
        guard let requestID = visibleImageRequestIDs.removeValue(
            forKey: itemID
        ) else {
            return
        }

        imageLoader.cancelImageRequest(requestID)
    }
}

// MARK: - UICollectionViewDataSourcePrefetching
/// 곧 보일 이미지의 다운로드를 시작하고, 필요 없어지면 취소합니다.
extension PrefetchImageInfiniteScrollViewController:
    UICollectionViewDataSourcePrefetching
{

    /// UIKit이 곧 표시할 Item의 이미지 URL을 미리 준비합니다.
    func collectionView(
        _ collectionView: UICollectionView,
        prefetchItemsAt indexPaths: [IndexPath]
    ) {
        imageLoader.prefetch(imageURLs(for: indexPaths))
    }

    /// 더 이상 곧 표시되지 않을 Item의 이미지 prefetch를 취소합니다.
    func collectionView(
        _ collectionView: UICollectionView,
        cancelPrefetchingForItemsAt indexPaths: [IndexPath]
    ) {
        imageLoader.cancelPrefetching(imageURLs(for: indexPaths))
    }
}

/// 이미지 피드 Item과 이미지 요청 결과를 표시하는 셀입니다.
private final class PrefetchImageFeedCollectionViewCell:
    UICollectionViewCell
{

    static let reuseIdentifier = "PrefetchImageFeedCollectionViewCell"

    private var representedItemID: Int?

    private let thumbnailImageView: UIImageView = {
        let imageView = UIImageView(
            image: UIImage(systemName: "photo")
        )
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.tintColor = .tertiaryLabel
        imageView.backgroundColor = .secondarySystemFill
        imageView.layer.cornerRadius = 12
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .label
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .secondaryLabel
        label.numberOfLines = 2
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let sourceLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption2)
        label.textColor = .tertiaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var textStackView: UIStackView = {
        let stackView = UIStackView(
            arrangedSubviews: [titleLabel, subtitleLabel, sourceLabel]
        )
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.backgroundColor = .secondarySystemBackground
        contentView.layer.cornerRadius = 16
        contentView.layer.masksToBounds = true

        contentView.addSubview(thumbnailImageView)
        contentView.addSubview(textStackView)

        NSLayoutConstraint.activate([
            thumbnailImageView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: 16
            ),
            thumbnailImageView.centerYAnchor.constraint(
                equalTo: contentView.centerYAnchor
            ),
            thumbnailImageView.widthAnchor.constraint(equalToConstant: 112),
            thumbnailImageView.heightAnchor.constraint(equalToConstant: 84),

            textStackView.leadingAnchor.constraint(
                equalTo: thumbnailImageView.trailingAnchor,
                constant: 14
            ),
            textStackView.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -16
            ),
            textStackView.centerYAnchor.constraint(
                equalTo: thumbnailImageView.centerYAnchor
            )
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        representedItemID = nil
        thumbnailImageView.image = UIImage(systemName: "photo")
        thumbnailImageView.tintColor = .tertiaryLabel
        thumbnailImageView.backgroundColor = .secondarySystemFill
        titleLabel.text = nil
        subtitleLabel.text = nil
        sourceLabel.text = nil
    }

    /// Item 모델을 표시하고 이미지 요청 전 placeholder 상태로 초기화합니다.
    func configure(
        item: PrefetchImageInfiniteScrollViewController.FeedItem
    ) {
        representedItemID = item.id
        thumbnailImageView.image = UIImage(systemName: "photo")
        thumbnailImageView.tintColor = .tertiaryLabel
        thumbnailImageView.backgroundColor = .secondarySystemFill
        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
        sourceLabel.text = String(item.page) + "페이지 · 이미지 요청 대기"
    }

    /// Item ID가 같은 셀에만 이미지 요청 결과를 적용합니다.
    func configureImage(
        _ image: UIImage?,
        source: ImageInfiniteScrollImageLoader.Source?,
        itemID: Int,
        page: Int
    ) {
        guard representedItemID == itemID else {
            return
        }

        guard let image else {
            sourceLabel.text = String(page) + "페이지 · 불러오기 실패"
            return
        }

        thumbnailImageView.image = image
        thumbnailImageView.backgroundColor = .clear
        switch source {
        case .memoryCache:
            sourceLabel.text = String(page) + "페이지 · prefetch cache"
        case .network:
            sourceLabel.text = String(page) + "페이지 · network load"
        case nil:
            sourceLabel.text = String(page) + "페이지"
        }
    }
}

#Preview {
    PrefetchImageInfiniteScrollViewController()
}
