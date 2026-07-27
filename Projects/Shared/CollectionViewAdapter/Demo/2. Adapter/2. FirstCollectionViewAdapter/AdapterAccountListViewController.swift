//
//  AdapterAccountListViewController.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/21/26.
//

import UIKit

final class AdapterAccountListViewController:
    UIViewController {

    private let accounts: [BankAccount]

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()

        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(
            top: 20,
            left: 20,
            bottom: 20,
            right: 20
        )

        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: layout
        )

        collectionView.backgroundColor = .systemBackground
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        return collectionView
    }()

    private lazy var adapter = FirstCollectionViewAdapter(
        collectionView: collectionView
    )

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
        render()
    }

    private func configureNavigation() {
        title = "Adapter 방식"
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

    private func render() {
        let itemModels: [any CellItemModelType] =
            accounts.map { account in
                AccountCellItemModel(
                    account: account,
                    onTouch: { [weak self] in
                        self?.showAccountDetail(
                            account: account
                        )
                    },
                    onTransfer: { [weak self] in
                        self?.showTransfer(
                            account: account
                        )
                    }
                )
            }

        adapter.setItems(itemModels)
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
