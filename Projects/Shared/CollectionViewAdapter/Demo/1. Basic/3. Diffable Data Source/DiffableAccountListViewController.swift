//
//  DiffableAccountListViewController.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/28/26.
//

import UIKit

final class DiffableAccountListViewController: UIViewController {

    private enum Section: Hashable {
        case account
    }

    private typealias DataSource = UICollectionViewDiffableDataSource<
        Section,
        UUID
    >

    private let accounts: [BankAccount]
    private let accountsByID: [UUID: BankAccount]

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: Self.makeLayout()
        )

        collectionView.backgroundColor = .systemBackground
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
            AccountListSupplementaryView.self,
            forSupplementaryViewOfKind:
                UICollectionView.elementKindSectionFooter,
            withReuseIdentifier:
                AccountListSupplementaryView.reuseIdentifier
        )

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()

    private lazy var dataSource: DataSource = makeDataSource()

    init(accounts: [BankAccount]) {
        self.accounts = accounts
        self.accountsByID = Dictionary(
            uniqueKeysWithValues: accounts.map { account in
                (account.id, account)
            }
        )

        super.init(
            nibName: nil,
            bundle: nil
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigation()
        configureLayout()
        applySnapshot(animatingDifferences: false)
    }

    private func configureNavigation() {
        title = "Diffable Data Source"
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

    /// 셀과 supplementary view provider가 연결된 Diffable Data Source를 생성합니다.
    ///
    /// item identifier로 계좌의 `UUID`를 사용해 snapshot의 항목과
    /// 실제 계좌 모델을 안정적으로 연결합니다.
    private func makeDataSource() -> DataSource {
        let dataSource = DataSource(
            collectionView: collectionView
        ) { [weak self] collectionView, indexPath, accountID in
            guard
                let self,
                let account = self.accountsByID[accountID],
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier:
                        AccountCollectionViewCell.reuseIdentifier,
                    for: indexPath
                ) as? AccountCollectionViewCell
            else {
                assertionFailure("AccountCollectionViewCell 생성 실패")
                return nil
            }

            cell.configure(
                account: account,
                onTransfer: { [weak self] in
                    self?.showTransfer(account: account)
                }
            )

            return cell
        }

        dataSource.supplementaryViewProvider = {
            collectionView,
            kind,
            indexPath in
            guard let supplementaryView = collectionView
                .dequeueReusableSupplementaryView(
                    ofKind: kind,
                    withReuseIdentifier:
                        AccountListSupplementaryView.reuseIdentifier,
                    for: indexPath
                ) as? AccountListSupplementaryView
            else {
                assertionFailure("AccountListSupplementaryView 생성 실패")
                return nil
            }

            switch kind {
            case UICollectionView.elementKindSectionHeader:
                supplementaryView.configure(kind: .header)

            case UICollectionView.elementKindSectionFooter:
                supplementaryView.configure(kind: .footer)

            default:
                assertionFailure("지원하지 않는 supplementary view kind입니다.")
                return nil
            }

            return supplementaryView
        }

        return dataSource
    }

    /// 현재 계좌 목록을 Diffable snapshot으로 변환해 컬렉션 뷰에 적용합니다.
    ///
    /// - Parameter animatingDifferences: snapshot 변경 애니메이션 적용 여부입니다.
    private func applySnapshot(
        animatingDifferences: Bool
    ) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, UUID>()

        snapshot.appendSections([.account])
        snapshot.appendItems(
            accounts.map(\.id),
            toSection: .account
        )

        dataSource.apply(
            snapshot,
            animatingDifferences: animatingDifferences
        )
    }

    private func showAccountDetail(
        account: BankAccount
    ) {
        let alert = UIAlertController(
            title: account.name,
            message: "잔액은 \(account.balanceText)입니다.",
            preferredStyle: .alert
        )

        alert.addAction(
            UIAlertAction(
                title: "확인",
                style: .default
            )
        )

        present(alert, animated: true)
    }

    private func showTransfer(
        account: BankAccount
    ) {
        let alert = UIAlertController(
            title: "송금",
            message: "\(account.name)에서 송금합니다.",
            preferredStyle: .alert
        )

        alert.addAction(
            UIAlertAction(
                title: "확인",
                style: .default
            )
        )

        present(alert, animated: true)
    }

    private static func makeLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .absolute(84)
        )
        let item = NSCollectionLayoutItem(
            layoutSize: itemSize
        )
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
        let section = NSCollectionLayoutSection(
            group: group
        )

        section.interGroupSpacing = 12
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 12,
            leading: 0,
            bottom: 12,
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

        return UICollectionViewCompositionalLayout(
            section: section
        )
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

// MARK: - UICollectionViewDelegate
/// Diffable snapshot의 item identifier를 이용해 계좌 셀 선택을 처리합니다.
extension DiffableAccountListViewController: UICollectionViewDelegate {

    /// 사용자가 선택한 셀의 item identifier로 계좌를 찾아 상세 정보를 표시합니다.
    ///
    /// - Parameters:
    ///   - collectionView: 선택 이벤트를 전달한 컬렉션 뷰입니다.
    ///   - indexPath: 사용자가 선택한 셀의 섹션과 아이템 위치입니다.
    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        guard
            let accountID = dataSource.itemIdentifier(for: indexPath),
            let account = accountsByID[accountID]
        else {
            return
        }

        showAccountDetail(account: account)
    }
}

#Preview {
    DiffableAccountListViewController(
        accounts: BankAccount.sample
    )
}
