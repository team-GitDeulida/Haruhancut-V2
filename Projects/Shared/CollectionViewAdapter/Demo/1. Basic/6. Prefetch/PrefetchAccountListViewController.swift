//
//  PrefetchAccountListViewController.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/28/26.
//

import UIKit

/**
 동작 흐름

 1. 사용자가 목록을 스크롤하면 UIKit이 곧 표시할 셀의 IndexPath를 전달합니다.
 2. prefetchItemsAt에서 계좌별 분석 데이터 준비 작업을 시작합니다.
 3. 작업이 끝나면 준비 완료 상태로 바꾸고, 현재 표시 중인 셀만 갱신합니다.
 4. 스크롤 방향이 바뀌어 더 이상 필요하지 않으면 UIKit이 취소를 요청합니다.
 5. cancelPrefetchingForItemsAt에서 작업을 취소해 불필요한 네트워크·메모리 사용을 막습니다.
 */

/// UICollectionViewDataSourcePrefetching으로 다음에 표시할 계좌 분석 데이터를
/// 미리 준비하고, 필요 없어지면 취소하는 예시입니다.
final class PrefetchAccountListViewController: UIViewController {

    fileprivate enum PrefetchState {
        case waiting
        case prefetching
        case prepared
        case cancelled

        var text: String {
            switch self {
            case .waiting:
                "대기 중"
            case .prefetching:
                "미리 준비 중"
            case .prepared:
                "준비 완료"
            case .cancelled:
                "미리 준비 취소됨"
            }
        }

        var tintColor: UIColor {
            switch self {
            case .waiting:
                .secondaryLabel
            case .prefetching:
                .systemOrange
            case .prepared:
                .systemGreen
            case .cancelled:
                .systemRed
            }
        }
    }

    private let sections = PrefetchAccountListViewController.makeSections()
    private var preparedAccountIDs: Set<UUID> = []
    private var prefetchingAccountIDs: Set<UUID> = []
    private var cancelledAccountIDs: Set<UUID> = []
    private var prefetchWorkItems: [UUID: DispatchWorkItem] = [:]

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: Self.makeLayout()
        )

        collectionView.backgroundColor = .systemBackground
        collectionView.alwaysBounceVertical = true
        collectionView.isPrefetchingEnabled = true
        collectionView.dataSource = self
        collectionView.prefetchDataSource = self
        collectionView.register(
            PrefetchAccountCollectionViewCell.self,
            forCellWithReuseIdentifier:
                PrefetchAccountCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            AccountListSupplementaryView.self,
            forSupplementaryViewOfKind:
                UICollectionView.elementKindSectionHeader,
            withReuseIdentifier:
                AccountListSupplementaryView.reuseIdentifier
        )
        collectionView.register(
            AccountListSupplementaryView.self,
            forSupplementaryViewOfKind:
                UICollectionView.elementKindSectionFooter,
            withReuseIdentifier:
                AccountListSupplementaryView.reuseIdentifier
        )

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()

    deinit {
        prefetchWorkItems.values.forEach { workItem in
            workItem.cancel()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigation()
        configureLayout()
    }

    private func configureNavigation() {
        title = "Prefetching"
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

    private func account(
        at indexPath: IndexPath
    ) -> BankAccount {
        sections[indexPath.section].accounts[indexPath.item]
    }

    /// 현재 계좌의 미리 준비 상태를 셀에 표시할 값으로 변환합니다.
    private func prefetchState(
        for account: BankAccount
    ) -> PrefetchState {
        if preparedAccountIDs.contains(account.id) {
            return .prepared
        }
        if prefetchingAccountIDs.contains(account.id) {
            return .prefetching
        }
        if cancelledAccountIDs.contains(account.id) {
            return .cancelled
        }
        return .waiting
    }

    /// UIKit이 미리 준비하라고 알려 준 계좌의 비동기 작업을 시작합니다.
    private func prefetch(
        accounts: [BankAccount]
    ) {
        for account in accounts {
            let accountID = account.id
            guard
                !preparedAccountIDs.contains(accountID),
                prefetchWorkItems[accountID] == nil
            else {
                continue
            }

            prefetchingAccountIDs.insert(accountID)
            cancelledAccountIDs.remove(accountID)

            let workItem = DispatchWorkItem { [weak self] in
                self?.finishPrefetching(accountID: accountID)
            }
            prefetchWorkItems[accountID] = workItem

            DispatchQueue.main.asyncAfter(
                deadline: .now() + 0.7,
                execute: workItem
            )
        }

        reloadVisibleItems(for: accounts)
    }

    /// UIKit이 더 이상 필요하지 않다고 알려 준 계좌의 준비 작업을 취소합니다.
    private func cancelPrefetching(
        accounts: [BankAccount]
    ) {
        for account in accounts {
            let accountID = account.id

            guard let workItem = prefetchWorkItems.removeValue(
                forKey: accountID
            ) else {
                continue
            }

            workItem.cancel()
            prefetchingAccountIDs.remove(accountID)
            cancelledAccountIDs.insert(accountID)
        }

        reloadVisibleItems(for: accounts)
    }

    /// 모의 네트워크 작업이 끝난 계좌를 준비 완료 상태로 변경합니다.
    private func finishPrefetching(
        accountID: UUID
    ) {
        guard prefetchWorkItems.removeValue(forKey: accountID) != nil else {
            return
        }

        prefetchingAccountIDs.remove(accountID)
        preparedAccountIDs.insert(accountID)
        cancelledAccountIDs.remove(accountID)
        reloadVisibleItem(accountID: accountID)
    }

    /// 보이는 셀 중 상태가 변경된 계좌만 다시 구성합니다.
    private func reloadVisibleItems(
        for accounts: [BankAccount]
    ) {
        let accountIDs = Set(accounts.map(\.id))
        let indexPaths = collectionView.indexPathsForVisibleItems.filter {
            accountIDs.contains(account(at: $0).id)
        }

        guard !indexPaths.isEmpty else {
            return
        }

        collectionView.reloadItems(at: indexPaths)
    }

    /// 계좌 식별자로 현재 보이는 셀의 상태를 갱신합니다.
    private func reloadVisibleItem(
        accountID: UUID
    ) {
        guard let indexPath = collectionView.indexPathsForVisibleItems.first(
            where: { account(at: $0).id == accountID }
        ) else {
            return
        }

        collectionView.reloadItems(at: [indexPath])
    }

    private static func makeSections() -> [BankAccountSection] {
        let accounts = (1...30).map { index in
            BankAccount(
                id: UUID(),
                name: "분석 대상 통장 (index)",
                balance: 50_000 + (index * 37_500)
            )
        }

        return [
            BankAccountSection(
                id: "prefetchAccounts",
                title: "계좌 분석 데이터",
                description: "스크롤하면 다음 셀의 분석 데이터를 미리 준비합니다.",
                accounts: accounts
            )
        ]
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
                height: AccountListSupplementaryView.footerHeight,
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
/// 계좌 분석 목록의 섹션, 셀, supplementary view를 제공합니다.
extension PrefetchAccountListViewController: UICollectionViewDataSource {

    /// 계좌 분석 목록에 표시할 섹션 개수를 반환합니다.
    func numberOfSections(
        in collectionView: UICollectionView
    ) -> Int {
        sections.count
    }

    /// 지정된 섹션에 표시할 계좌 아이템 개수를 반환합니다.
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        sections[section].accounts.count
    }

    /// 계좌 정보와 현재 prefetch 상태로 셀을 구성합니다.
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier:
                PrefetchAccountCollectionViewCell.reuseIdentifier,
            for: indexPath
        ) as? PrefetchAccountCollectionViewCell else {
            assertionFailure("PrefetchAccountCollectionViewCell 생성 실패")
            return UICollectionViewCell()
        }

        let account = account(at: indexPath)
        cell.configure(
            account: account,
            state: prefetchState(for: account)
        )
        return cell
    }

    /// 지정한 종류에 맞는 섹션 header 또는 footer를 생성하고 설정합니다.
    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard let supplementaryView = collectionView
            .dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier:
                    AccountListSupplementaryView.reuseIdentifier,
                for: indexPath
            ) as? AccountListSupplementaryView else {
            assertionFailure("AccountListSupplementaryView 생성 실패")
            return UICollectionReusableView()
        }

        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let section = sections[indexPath.section]
            supplementaryView.configure(
                kind: .header,
                title: section.title,
                description: section.description
            )

        case UICollectionView.elementKindSectionFooter:
            supplementaryView.configure(
                kind: .footer,
                footerText: "준비 완료된 셀은 캐시 데이터를 바로 사용합니다."
            )

        default:
            assertionFailure("지원하지 않는 supplementary view kind입니다.")
        }

        return supplementaryView
    }
}

// MARK: - UICollectionViewDataSourcePrefetching
/// 곧 표시될 계좌의 분석 데이터를 미리 준비하거나 취소합니다.
extension PrefetchAccountListViewController:
    UICollectionViewDataSourcePrefetching
{

    /// UIKit이 곧 화면에 표시할 아이템의 준비를 요청할 때 호출됩니다.
    ///
    /// - Parameters:
    ///   - collectionView: prefetch 요청을 전달한 컬렉션 뷰입니다.
    ///   - indexPaths: 곧 표시될 아이템의 위치입니다.
    func collectionView(
        _ collectionView: UICollectionView,
        prefetchItemsAt indexPaths: [IndexPath]
    ) {
        prefetch(accounts: indexPaths.map(account(at:)))
    }

    /// UIKit이 더 이상 곧 표시되지 않을 아이템의 준비 취소를 요청할 때 호출됩니다.
    ///
    /// - Parameters:
    ///   - collectionView: prefetch 취소 요청을 전달한 컬렉션 뷰입니다.
    ///   - indexPaths: 미리 준비할 필요가 없어진 아이템의 위치입니다.
    func collectionView(
        _ collectionView: UICollectionView,
        cancelPrefetchingForItemsAt indexPaths: [IndexPath]
    ) {
        cancelPrefetching(accounts: indexPaths.map(account(at:)))
    }
}

/// 계좌 정보와 prefetch 상태를 표시하는 전용 셀입니다.
private final class PrefetchAccountCollectionViewCell: UICollectionViewCell {

    static let reuseIdentifier = "PrefetchAccountCollectionViewCell"

    private let iconView: UIImageView = {
        let configuration = UIImage.SymbolConfiguration(
            pointSize: 18,
            weight: .bold
        )
        let imageView = UIImageView(
            image: UIImage(
                systemName: "arrow.down.circle.fill",
                withConfiguration: configuration
            )
        )
        imageView.tintColor = .systemBlue
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let balanceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .bold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let stateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textAlignment = .center
        label.layer.cornerRadius = 10
        label.layer.masksToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        configureStyle()
        configureLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        nameLabel.text = nil
        balanceLabel.text = nil
        stateLabel.text = nil
    }

    /// 계좌 정보와 해당 계좌의 미리 준비 상태를 화면에 표시합니다.
    func configure(
        account: BankAccount,
        state: PrefetchAccountListViewController.PrefetchState
    ) {
        nameLabel.text = account.name
        balanceLabel.text = account.balanceText
        stateLabel.text = state.text
        stateLabel.textColor = state.tintColor
        stateLabel.backgroundColor = state.tintColor.withAlphaComponent(0.12)
    }

    private func configureStyle() {
        contentView.backgroundColor = .secondarySystemBackground
        contentView.layer.cornerRadius = 16
        contentView.layer.masksToBounds = true
    }

    private func configureLayout() {
        contentView.addSubview(iconView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(balanceLabel)
        contentView.addSubview(stateLabel)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: 16
            ),
            iconView.centerYAnchor.constraint(
                equalTo: contentView.centerYAnchor
            ),
            iconView.widthAnchor.constraint(equalToConstant: 28),
            iconView.heightAnchor.constraint(equalToConstant: 28),

            nameLabel.topAnchor.constraint(
                equalTo: contentView.topAnchor,
                constant: 18
            ),
            nameLabel.leadingAnchor.constraint(
                equalTo: iconView.trailingAnchor,
                constant: 12
            ),
            nameLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: stateLabel.leadingAnchor,
                constant: -12
            ),

            balanceLabel.topAnchor.constraint(
                equalTo: nameLabel.bottomAnchor,
                constant: 4
            ),
            balanceLabel.leadingAnchor.constraint(
                equalTo: nameLabel.leadingAnchor
            ),
            balanceLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: stateLabel.leadingAnchor,
                constant: -12
            ),

            stateLabel.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -16
            ),
            stateLabel.centerYAnchor.constraint(
                equalTo: contentView.centerYAnchor
            ),
            stateLabel.widthAnchor.constraint(equalToConstant: 104),
            stateLabel.heightAnchor.constraint(equalToConstant: 28)
        ])
    }
}

#Preview {
    PrefetchAccountListViewController()
}
