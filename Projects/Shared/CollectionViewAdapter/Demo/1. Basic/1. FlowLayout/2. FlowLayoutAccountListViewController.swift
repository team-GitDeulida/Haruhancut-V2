//
//  FlowLayoutAccountListViewController.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/21/26.
//

import UIKit

final class FlowLayoutAccountListViewController: UIViewController {

    private let accounts: [BankAccount]

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()

        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(
            top: 12,
            left: 20,
            bottom: 12,
            right: 20
        )
        layout.headerReferenceSize = CGSize(
            width: 0,
            height: AccountListSupplementaryView.headerHeight
        )
        layout.footerReferenceSize = CGSize(
            width: 0,
            height: AccountListSupplementaryView.footerHeight
        )

        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: layout
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
        title = "FlowLayout"
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
}

// MARK: - UICollectionViewDataSource
/// 계좌 목록 컬렉션 뷰에 표시할 데이터와 셀 생성을 담당합니다.
extension FlowLayoutAccountListViewController:
    UICollectionViewDataSource {

    /// 지정된 섹션에 표시할 계좌 셀의 개수를 반환합니다.
    ///
    /// - Parameters:
    ///   - collectionView: 아이템 개수를 요청한 컬렉션 뷰입니다.
    ///   - section: 아이템 개수를 확인할 섹션의 인덱스입니다.
    /// - Returns: `accounts` 배열에 저장된 계좌 개수입니다.
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        accounts.count
    }

    /// 지정된 위치에 표시할 계좌 셀을 생성하고 데이터를 설정합니다.
    ///
    /// 재사용 큐에서 `AccountCollectionViewCell`을 가져온 뒤,
    /// 현재 위치에 해당하는 계좌 정보와 송금 버튼 동작을 전달합니다.
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

        let account = accounts[indexPath.item]

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
extension FlowLayoutAccountListViewController:
    UICollectionViewDelegate {

    /// 사용자가 계좌 셀을 선택했을 때 호출됩니다.
    ///
    /// 선택한 위치의 계좌 데이터를 가져와 계좌 상세 화면을 표시합니다.
    ///
    /// - Parameters:
    ///   - collectionView: 셀이 선택된 컬렉션 뷰입니다.
    ///   - indexPath: 사용자가 선택한 셀의 섹션과 아이템 위치입니다.
    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        let account = accounts[indexPath.item]
        showAccountDetail(account: account)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
/// 계좌 목록 컬렉션 뷰에서 사용하는 셀의 크기를 설정합니다.
extension FlowLayoutAccountListViewController:
    UICollectionViewDelegateFlowLayout {

    /// 지정된 위치에 표시할 계좌 셀의 크기를 반환합니다.
    ///
    /// 셀의 너비는 컬렉션 뷰 전체 너비에서 섹션의 좌우 여백을 제외한 값이며,
    /// 높이는 `84`포인트로 고정합니다.
    ///
    /// - Parameters:
    ///   - collectionView: 셀을 표시할 컬렉션 뷰입니다.
    ///   - collectionViewLayout: 컬렉션 뷰에 적용된 레이아웃 객체입니다.
    ///   - indexPath: 크기를 계산할 셀의 섹션과 아이템 위치입니다.
    /// - Returns: 계산된 셀의 너비와 높이입니다. Flow Layout이 아니면 `.zero`를 반환합니다.
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        guard let layout =
                collectionViewLayout as? UICollectionViewFlowLayout
        else {
            return .zero
        }

        let horizontalInset =
            layout.sectionInset.left
            + layout.sectionInset.right

        return CGSize(
            width: collectionView.bounds.width - horizontalInset,
            height: 84
        )
    }
}

#Preview {
    FlowLayoutAccountListViewController(accounts: BankAccount.sample)
}
