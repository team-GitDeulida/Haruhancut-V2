//
//  ScrollInfiniteAccountListViewController.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/28/26.
//

import UIKit

/**
 동작 흐름

 1. scrollViewDidScroll과 scrollViewWillEndDragging에서 현재 또는 예상 위치를 확인합니다.
 2. 목록 끝에서 viewport 1.5배 거리 안으로 들어오면 다음 페이지를 한 번 요청합니다.
 3. 요청이 끝나면 일반 UICollectionViewDataSource의 아이템 수를 늘리고 reloadData를 호출합니다.
 4. 로딩 중에는 중복 요청하지 않고, 요청이 끝나면 다시 다음 페이지를 요청할 수 있습니다.
 */

/// UIScrollViewDelegate의 스크롤 위치로 다음 계좌 페이지를 요청하는 예시입니다.
final class ScrollInfiniteAccountListViewController: UIViewController {

    private enum Constant {
        static let pageSize = 12
        static let simulatedNetworkDelay: TimeInterval = 0.7
    }

    private var accounts: [BankAccount] = []
    private var nextPage = 0
    private var isLoadingNextPage = false
    private var loadingWorkItem: DispatchWorkItem?

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: Self.makeLayout()
        )

        collectionView.backgroundColor = .systemBackground
        collectionView.alwaysBounceVertical = true
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            AccountCollectionViewCell.self,
            forCellWithReuseIdentifier:
                AccountCollectionViewCell.reuseIdentifier
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
        title = "Scroll Infinite"
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

    /// 끝 접근 조건을 만족하면 다음 계좌 페이지 요청을 시작합니다.
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
        let triggerDistance = viewportLength * 1.5

        guard remainingDistance <= triggerDistance else {
            return
        }

        loadNextPage()
    }

    /// 페이지 요청 상태를 변경하고 모의 네트워크 응답을 예약합니다.
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

    /// 다음 페이지의 계좌 모델을 일반 배열에 추가합니다.
    private func appendPage() {
        let page = nextPage
        let firstIndex = page * Constant.pageSize
        let newAccounts = (0..<Constant.pageSize).map { offset in
            let index = firstIndex + offset
            return BankAccount(
                id: UUID(),
                name: "스크롤 계좌 " + String(index + 1),
                balance: 100_000 + (index * 28_000)
            )
        }

        accounts.append(contentsOf: newAccounts)
        nextPage += 1
    }

    /// 현재 보이는 footer만 즉시 갱신해 로딩 상태를 보여 줍니다.
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

    private static func makeLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .absolute(84)
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
/// 일반 배열을 사용해 계좌 셀과 supplementary view를 구성합니다.
extension ScrollInfiniteAccountListViewController: UICollectionViewDataSource {

    /// 하나의 계좌 목록 섹션을 반환합니다.
    func numberOfSections(
        in collectionView: UICollectionView
    ) -> Int {
        1
    }

    /// 지금까지 불러온 계좌 수만큼 아이템을 표시합니다.
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        accounts.count
    }

    /// 지정된 위치의 계좌 정보와 송금 동작으로 셀을 구성합니다.
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier:
                AccountCollectionViewCell.reuseIdentifier,
            for: indexPath
        ) as? AccountCollectionViewCell else {
            assertionFailure("AccountCollectionViewCell 생성 실패")
            return UICollectionViewCell()
        }

        let account = accounts[indexPath.item]
        cell.configure(
            account: account,
            onTransfer: { [weak self] in
                self?.showTransfer(account: account)
            }
        )
        return cell
    }

    /// 헤더에는 예제 설명을, footer에는 다음 페이지 요청 상태를 표시합니다.
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
                title: "스크롤 기반 페이지 요청",
                description: "끝에서 한 화면 반 전부터 다음 페이지를 불러옵니다."
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
/// 현재 위치와 예상 정지 위치를 기준으로 다음 페이지 요청을 시작합니다.
extension ScrollInfiniteAccountListViewController: UICollectionViewDelegate {

    /// 스크롤 중 현재 위치가 threshold 안에 들어오면 다음 페이지를 요청합니다.
    func scrollViewDidScroll(
        _ scrollView: UIScrollView
    ) {
        loadNextPageIfNeeded(contentOffset: scrollView.contentOffset)
    }

    /// 손을 뗐을 때의 예상 정지 위치로 빠른 스크롤도 미리 처리합니다.
    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        loadNextPageIfNeeded(
            contentOffset: targetContentOffset.pointee
        )
    }
}

private extension ScrollInfiniteAccountListViewController {

    func showTransfer(
        account: BankAccount
    ) {
        let alert = UIAlertController(
            title: "송금",
            message: account.name + "에서 송금합니다.",
            preferredStyle: .alert
        )
        alert.addAction(
            UIAlertAction(title: "확인", style: .default)
        )
        present(alert, animated: true)
    }
}

#Preview {
    ScrollInfiniteAccountListViewController()
}
