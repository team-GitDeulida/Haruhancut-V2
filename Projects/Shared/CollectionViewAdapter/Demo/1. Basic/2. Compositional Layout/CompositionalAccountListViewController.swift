//
//  CompositionalAccountListViewController.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/28/26.
//

import UIKit

final class CompositionalAccountListViewController: UIViewController {

    private let sections: [BankAccountSection]

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

    init(sections: [BankAccountSection]) {
        self.sections = sections

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
/// 계좌 목록 컬렉션 뷰에 표시할 데이터와 보조 뷰 생성을 담당합니다.
extension CompositionalAccountListViewController:
    UICollectionViewDataSource {

    /// 계좌 목록에 표시할 섹션 개수를 반환합니다.
    ///
    /// - Parameter collectionView: 섹션 개수를 요청한 컬렉션 뷰입니다.
    /// - Returns: 현재 계좌 목록에 저장된 섹션 개수입니다.
    func numberOfSections(
        in collectionView: UICollectionView
    ) -> Int {
        sections.count
    }

    /// 지정된 섹션에 표시할 계좌 셀의 개수를 반환합니다.
    ///
    /// - Parameters:
    ///   - collectionView: 아이템 개수를 요청한 컬렉션 뷰입니다.
    ///   - section: 아이템 개수를 확인할 섹션의 인덱스입니다.
    /// - Returns: 해당 섹션에 저장된 계좌 개수입니다.
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        sections[section].accounts.count
    }

    /// 지정된 위치에 표시할 계좌 셀을 생성하고 데이터를 설정합니다.
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

        let account = sections[indexPath.section]
            .accounts[indexPath.item]

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
            let section = sections[indexPath.section]
            supplementaryView.configure(
                kind: .header,
                title: section.title,
                description: section.description
            )

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
extension CompositionalAccountListViewController:
    UICollectionViewDelegate {

    /// 사용자가 계좌 셀을 선택했을 때 상세 정보를 표시합니다.
    ///
    /// - Parameters:
    ///   - collectionView: 선택 이벤트를 전달한 컬렉션 뷰입니다.
    ///   - indexPath: 사용자가 선택한 셀의 섹션과 아이템 위치입니다.
    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        let account = sections[indexPath.section]
            .accounts[indexPath.item]
        showAccountDetail(account: account)
    }
}

#Preview {
    CompositionalAccountListViewController(
        sections: BankAccountSection.sample
    )
}
