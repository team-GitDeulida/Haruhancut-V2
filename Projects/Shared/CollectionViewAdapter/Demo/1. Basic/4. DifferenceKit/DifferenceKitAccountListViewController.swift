//
//  DifferenceKitAccountListViewController.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/28/26.
//

import DifferenceKit
import UIKit

/// DifferenceKit의 custom diffing으로 계좌 목록 변경을 적용하는 예시입니다.
final class DifferenceKitAccountListViewController: UIViewController {

    /// DifferenceKit이 사용할 계좌 항목입니다.
    ///
    /// 계좌 ID는 같은 항목을 식별하는 데만 사용하고, 이름과 잔액은
    /// 셀을 다시 그려야 하는 내용 변경으로 비교합니다.
    private struct AccountItem: Differentiable {
        let account: BankAccount

        var differenceIdentifier: UUID {
            account.id
        }

        func isContentEqual(
            to source: AccountItem
        ) -> Bool {
            account.name == source.account.name
                && account.balance == source.account.balance
        }
    }

    private var accounts: [AccountItem]

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
        self.accounts = accounts.map { account in
            AccountItem(account: account)
        }

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
    }

    private func configureNavigation() {
        title = "DifferenceKit"
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

    /// 새 계좌 목록을 현재 목록과 비교해 변경 단계를 컬렉션 뷰에 적용합니다.
    ///
    /// DifferenceKit은 section 및 item 변경을 안전한 순서의 단계로 나누므로,
    /// `setData` 클로저에서 각 단계의 데이터를 동기적으로 갱신해야 합니다.
    ///
    /// - Parameter accounts: 화면에 반영할 새 계좌 목록입니다.
    private func apply(
        accounts: [BankAccount]
    ) {
        let target = accounts.map { account in
            AccountItem(account: account)
        }
        let changeset = StagedChangeset(
            source: self.accounts,
            target: target
        )

        collectionView.reload(
            using: changeset,
            interrupt: { changeset in
                changeset.changeCount > 100
            },
            setData: { [unowned self] accounts in
                self.accounts = accounts
            }
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

// MARK: - UICollectionViewDataSource
/// DifferenceKit이 단계별로 갱신하는 계좌 목록을 컬렉션 뷰에 표시합니다.
extension DifferenceKitAccountListViewController: UICollectionViewDataSource {

    /// 계좌 목록에 표시할 아이템 개수를 반환합니다.
    ///
    /// - Parameters:
    ///   - collectionView: 아이템 개수를 요청한 컬렉션 뷰입니다.
    ///   - section: 아이템 개수를 확인할 섹션의 인덱스입니다.
    /// - Returns: 현재 DifferenceKit 데이터 소스에 저장된 계좌 개수입니다.
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        accounts.count
    }

    /// 지정된 위치의 계좌 항목으로 셀을 구성합니다.
    ///
    /// - Parameters:
    ///   - collectionView: 셀을 요청한 컬렉션 뷰입니다.
    ///   - indexPath: 생성할 셀의 섹션과 아이템 위치입니다.
    /// - Returns: 계좌 정보와 송금 동작이 설정된 컬렉션 뷰 셀입니다.
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

        let account = accounts[indexPath.item].account

        cell.configure(
            account: account,
            onTransfer: { [weak self] in
                self?.showTransfer(account: account)
            }
        )

        return cell
    }

    /// 지정한 종류에 맞는 섹션 header 또는 footer를 생성하고 설정합니다.
    ///
    /// - Parameters:
    ///   - collectionView: supplementary view를 요청한 컬렉션 뷰입니다.
    ///   - kind: 요청된 supplementary view의 종류입니다.
    ///   - indexPath: supplementary view가 표시될 섹션 위치입니다.
    /// - Returns: 설정이 완료된 header 또는 footer 뷰입니다.
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
/// 계좌 셀 선택과 같은 컬렉션 뷰의 사용자 상호작용을 처리합니다.
extension DifferenceKitAccountListViewController: UICollectionViewDelegate {

    /// 사용자가 계좌 셀을 선택했을 때 상세 정보를 표시합니다.
    ///
    /// - Parameters:
    ///   - collectionView: 선택 이벤트를 전달한 컬렉션 뷰입니다.
    ///   - indexPath: 사용자가 선택한 셀의 섹션과 아이템 위치입니다.
    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        showAccountDetail(
            account: accounts[indexPath.item].account
        )
    }
}

#Preview {
    DifferenceKitAccountListViewController(
        accounts: BankAccount.sample
    )
}
