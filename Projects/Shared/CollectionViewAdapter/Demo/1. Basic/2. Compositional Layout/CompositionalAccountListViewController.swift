//
//  CompositionalAccountListViewController.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/28/26.
//

import UIKit

final class CompositionalAccountListViewController: UIViewController {

    private let accounts: [BankAccount]

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: Self.makeLayout()
        )

        collectionView.backgroundColor = .systemBackground
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
            AccountListSupplementaryView.self,
            forSupplementaryViewOfKind:
                UICollectionView.elementKindSectionFooter,
            withReuseIdentifier:
                AccountListSupplementaryView.reuseIdentifier
        )

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()

    init(accounts: [BankAccount]) {
        self.accounts = accounts

        super.init(
            nibName: nil,
            bundle: nil
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigation()
        configureLayout()
    }

    private func configureNavigation() {
        title = "기본 UICollectionView"
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

// MARK: - UICollectionViewDataSource
extension CompositionalAccountListViewController:
    UICollectionViewDataSource {

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        accounts.count
    }

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
            ) as? AccountListSupplementaryView
        else {
            assertionFailure("AccountListSupplementaryView 생성 실패")
            return UICollectionReusableView()
        }

        switch kind {
        case UICollectionView.elementKindSectionHeader:
            supplementaryView.configure(kind: .header)

        case UICollectionView.elementKindSectionFooter:
            supplementaryView.configure(kind: .footer)

        default:
            assertionFailure("지원하지 않는 supplementary view kind입니다.")
        }

        return supplementaryView
    }
}

// MARK: - UICollectionViewDelegate
extension CompositionalAccountListViewController:
    UICollectionViewDelegate {

    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        let account = accounts[indexPath.item]
        showAccountDetail(account: account)
    }
}

#Preview {
    CompositionalAccountListViewController(
        accounts: BankAccount.sample
    )
}
