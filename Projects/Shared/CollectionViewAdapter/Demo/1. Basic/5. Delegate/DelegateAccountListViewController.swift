//
//  DelegateAccountListViewController.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/28/26.
//

import UIKit

/// UICollectionViewDataSource와 주요 UICollectionViewDelegate 이벤트를 보여주는 예시입니다.
final class DelegateAccountListViewController: UIViewController {

    private let sections: [BankAccountSection]

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: Self.makeLayout()
        )

        collectionView.backgroundColor = .systemBackground
        collectionView.allowsSelection = true
        collectionView.allowsMultipleSelection = false
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
        title = "Delegate Events"
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

    /// 선택 허용 여부를 판단할 계좌를 반환합니다.
    private func account(
        at indexPath: IndexPath
    ) -> BankAccount {
        sections[indexPath.section].accounts[indexPath.item]
    }

    /// 선택 허용 delegate를 보여 주기 위한 예시 규칙입니다.
    ///
    /// 잔액이 100,000원 미만인 계좌는 길게 누르기는 가능하지만 탭 선택은 허용하지 않습니다.
    private func isSelectable(
        account: BankAccount
    ) -> Bool {
        account.balance >= 100_000
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
/// 계좌 목록의 섹션, 셀, supplementary view를 제공합니다.
extension DelegateAccountListViewController: UICollectionViewDataSource {

    /// 계좌 목록에 표시할 섹션 개수를 반환합니다.
    ///
    /// - Parameter collectionView: 섹션 개수를 요청한 컬렉션 뷰입니다.
    /// - Returns: 현재 계좌 목록에 저장된 섹션 개수입니다.
    func numberOfSections(
        in collectionView: UICollectionView
    ) -> Int {
        sections.count
    }

    /// 지정된 섹션에 표시할 계좌 아이템 개수를 반환합니다.
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

    /// 지정된 위치의 계좌 정보와 송금 동작으로 셀을 구성합니다.
    ///
    /// - Parameters:
    ///   - collectionView: 셀을 요청한 컬렉션 뷰입니다.
    ///   - indexPath: 생성할 셀의 섹션과 아이템 위치입니다.
    /// - Returns: 계좌 정보가 설정된 컬렉션 뷰 셀입니다.
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

        let account = account(at: indexPath)

        cell.configure(
            account: account,
            onTransfer: { [weak self] in
                self?.showTransfer(account: account)
            }
        )
        cell.alpha = isSelectable(account: account) ? 1 : 0.55

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
/// 계좌 셀의 선택, 길게 누르기, 표시 lifecycle 이벤트를 처리합니다.
extension DelegateAccountListViewController: UICollectionViewDelegate {

    /// 지정된 계좌를 탭으로 선택할 수 있는지 결정합니다.
    ///
    /// - Parameters:
    ///   - collectionView: 선택 가능 여부를 요청한 컬렉션 뷰입니다.
    ///   - indexPath: 선택하려는 셀의 섹션과 아이템 위치입니다.
    /// - Returns: 잔액이 100,000원 이상이면 `true`입니다.
    func collectionView(
        _ collectionView: UICollectionView,
        shouldSelectItemAt indexPath: IndexPath
    ) -> Bool {
        isSelectable(account: account(at: indexPath))
    }

    /// 선택된 계좌의 상세 정보를 표시합니다.
    ///
    /// - Parameters:
    ///   - collectionView: 선택 이벤트를 전달한 컬렉션 뷰입니다.
    ///   - indexPath: 선택한 셀의 섹션과 아이템 위치입니다.
    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        showAccountDetail(account: account(at: indexPath))
    }

    /// 현재 선택된 계좌의 선택 해제를 허용할지 결정합니다.
    ///
    /// - Parameters:
    ///   - collectionView: 선택 해제 가능 여부를 요청한 컬렉션 뷰입니다.
    ///   - indexPath: 선택 해제하려는 셀의 섹션과 아이템 위치입니다.
    /// - Returns: 항상 `true`를 반환해 다른 계좌 선택 시 이전 선택을 해제합니다.
    func collectionView(
        _ collectionView: UICollectionView,
        shouldDeselectItemAt indexPath: IndexPath
    ) -> Bool {
        true
    }

    /// 계좌 셀의 선택이 해제된 뒤 호출됩니다.
    ///
    /// - Parameters:
    ///   - collectionView: 선택 해제 이벤트를 전달한 컬렉션 뷰입니다.
    ///   - indexPath: 선택이 해제된 셀의 섹션과 아이템 위치입니다.
    func collectionView(
        _ collectionView: UICollectionView,
        didDeselectItemAt indexPath: IndexPath
    ) {
        collectionView.cellForItem(at: indexPath)?.transform = .identity
    }

    /// 셀을 누르는 동안 highlight를 허용할지 결정합니다.
    ///
    /// - Parameters:
    ///   - collectionView: highlight 가능 여부를 요청한 컬렉션 뷰입니다.
    ///   - indexPath: highlight하려는 셀의 섹션과 아이템 위치입니다.
    /// - Returns: 선택 가능한 계좌일 때만 `true`입니다.
    func collectionView(
        _ collectionView: UICollectionView,
        shouldHighlightItemAt indexPath: IndexPath
    ) -> Bool {
        isSelectable(account: account(at: indexPath))
    }

    /// 셀을 누르는 동안 축소 효과를 적용합니다.
    ///
    /// - Parameters:
    ///   - collectionView: highlight 이벤트를 전달한 컬렉션 뷰입니다.
    ///   - indexPath: highlight된 셀의 섹션과 아이템 위치입니다.
    func collectionView(
        _ collectionView: UICollectionView,
        didHighlightItemAt indexPath: IndexPath
    ) {
        UIView.animate(withDuration: 0.15) {
            collectionView.cellForItem(at: indexPath)?
                .transform = CGAffineTransform(
                    scaleX: 0.98,
                    y: 0.98
                )
        }
    }

    /// highlight가 끝난 셀의 크기를 원래대로 되돌립니다.
    ///
    /// - Parameters:
    ///   - collectionView: highlight 해제 이벤트를 전달한 컬렉션 뷰입니다.
    ///   - indexPath: highlight가 해제된 셀의 섹션과 아이템 위치입니다.
    func collectionView(
        _ collectionView: UICollectionView,
        didUnhighlightItemAt indexPath: IndexPath
    ) {
        UIView.animate(withDuration: 0.15) {
            collectionView.cellForItem(at: indexPath)?
                .transform = .identity
        }
    }

    /// 셀이 화면에 표시되기 직전에 fade-in 애니메이션을 적용합니다.
    ///
    /// - Parameters:
    ///   - collectionView: 표시 이벤트를 전달한 컬렉션 뷰입니다.
    ///   - cell: 화면에 표시될 셀입니다.
    ///   - indexPath: 표시될 셀의 섹션과 아이템 위치입니다.
    func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        cell.alpha = 0
        cell.transform = CGAffineTransform(
            translationX: 0,
            y: 12
        )

        UIView.animate(withDuration: 0.25) {
            cell.alpha = self.isSelectable(
                account: self.account(at: indexPath)
            ) ? 1 : 0.55
            cell.transform = .identity
        }
    }

    /// 셀이 화면에서 사라진 뒤 진행 중인 애니메이션을 정리합니다.
    ///
    /// - Parameters:
    ///   - collectionView: 화면 이탈 이벤트를 전달한 컬렉션 뷰입니다.
    ///   - cell: 화면에서 사라진 셀입니다.
    ///   - indexPath: 사라진 셀의 섹션과 아이템 위치입니다.
    func collectionView(
        _ collectionView: UICollectionView,
        didEndDisplaying cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        cell.layer.removeAllAnimations()
    }

    /// 길게 누른 계좌에 표시할 context menu를 구성합니다.
    ///
    /// - Parameters:
    ///   - collectionView: context menu를 요청한 컬렉션 뷰입니다.
    ///   - indexPath: 길게 누른 셀의 섹션과 아이템 위치입니다.
    ///   - point: 컬렉션 뷰 좌표계의 길게 누른 위치입니다.
    /// - Returns: 잔액 보기와 송금 action이 포함된 context menu입니다.
    func collectionView(
        _ collectionView: UICollectionView,
        contextMenuConfigurationForItemAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        let account = account(at: indexPath)

        return UIContextMenuConfiguration(
            identifier: account.id as NSCopying,
            previewProvider: nil
        ) { [weak self] _ in
            let balanceAction = UIAction(
                title: "잔액 보기",
                image: UIImage(systemName: "wonsign.circle")
            ) { _ in
                self?.showAccountDetail(account: account)
            }
            let transferAction = UIAction(
                title: "송금",
                image: UIImage(systemName: "arrow.right.circle")
            ) { _ in
                self?.showTransfer(account: account)
            }

            return UIMenu(
                children: [balanceAction, transferAction]
            )
        }
    }

    /// 화면에 표시되기 직전의 supplementary view에 fade-in 효과를 적용합니다.
    ///
    /// - Parameters:
    ///   - collectionView: 표시 이벤트를 전달한 컬렉션 뷰입니다.
    ///   - view: 화면에 표시될 supplementary view입니다.
    ///   - elementKind: supplementary view의 종류입니다.
    ///   - indexPath: 표시될 supplementary view의 섹션 위치입니다.
    func collectionView(
        _ collectionView: UICollectionView,
        willDisplaySupplementaryView view: UICollectionReusableView,
        forElementKind elementKind: String,
        at indexPath: IndexPath
    ) {
        view.alpha = 0

        UIView.animate(withDuration: 0.2) {
            view.alpha = 1
        }
    }

    /// 화면에서 사라진 supplementary view의 애니메이션을 정리합니다.
    ///
    /// - Parameters:
    ///   - collectionView: 화면 이탈 이벤트를 전달한 컬렉션 뷰입니다.
    ///   - view: 화면에서 사라진 supplementary view입니다.
    ///   - elementKind: supplementary view의 종류입니다.
    ///   - indexPath: 사라진 supplementary view의 섹션 위치입니다.
    func collectionView(
        _ collectionView: UICollectionView,
        didEndDisplayingSupplementaryView view: UICollectionReusableView,
        forElementOfKind elementKind: String,
        at indexPath: IndexPath
    ) {
        view.layer.removeAllAnimations()
    }
}

#Preview {
    DelegateAccountListViewController(
        sections: BankAccountSection.sample
    )
}
