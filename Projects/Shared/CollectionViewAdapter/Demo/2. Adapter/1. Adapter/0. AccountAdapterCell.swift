//
//  AccountAdapterCell.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/21/26.
//

import UIKit

final class AccountAdapterCell:
    UICollectionViewCell,
    CellItemModelBindable {

    private var onTransfer: (() -> Void)?

    private let iconView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBlue
        view.layer.cornerRadius = 20
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let iconLabel: UILabel = {
        let label = UILabel()
        label.text = "₩"
        label.textColor = .white
        label.font = .systemFont(
            ofSize: 18,
            weight: .bold
        )
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = .systemFont(
            ofSize: 15,
            weight: .medium
        )
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let balanceLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = .systemFont(
            ofSize: 17,
            weight: .bold
        )
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var transferButton: UIButton = {
        var configuration = UIButton.Configuration.gray()
        configuration.title = "송금"
        configuration.cornerStyle = .medium

        let button = UIButton(configuration: configuration)

        button.addTarget(
            self,
            action: #selector(transferButtonTapped),
            for: .touchUpInside
        )

        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        configureStyle()
        configureHierarchy()
        configureConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        nameLabel.text = nil
        balanceLabel.text = nil
        onTransfer = nil
    }

    func bind(
        itemModel: any CellItemModelType
    ) {
        guard let itemModel =
                itemModel as? AccountCellItemModel
        else {
            assertionFailure(
                "AccountAdapterCell은 AccountCellItemModel만 처리할 수 있습니다."
            )
            return
        }

        nameLabel.text = itemModel.account.name
        balanceLabel.text = itemModel.account.balanceText
        onTransfer = itemModel.onTransfer
    }

    private func configureStyle() {
        contentView.backgroundColor = .secondarySystemBackground
        contentView.layer.cornerRadius = 16
        contentView.layer.masksToBounds = true
    }

    private func configureHierarchy() {
        contentView.addSubview(iconView)
        iconView.addSubview(iconLabel)

        contentView.addSubview(nameLabel)
        contentView.addSubview(balanceLabel)
        contentView.addSubview(transferButton)
    }

    private func configureConstraints() {
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: 16
            ),
            iconView.centerYAnchor.constraint(
                equalTo: contentView.centerYAnchor
            ),
            iconView.widthAnchor.constraint(equalToConstant: 40),
            iconView.heightAnchor.constraint(equalToConstant: 40),

            iconLabel.topAnchor.constraint(
                equalTo: iconView.topAnchor
            ),
            iconLabel.leadingAnchor.constraint(
                equalTo: iconView.leadingAnchor
            ),
            iconLabel.trailingAnchor.constraint(
                equalTo: iconView.trailingAnchor
            ),
            iconLabel.bottomAnchor.constraint(
                equalTo: iconView.bottomAnchor
            ),

            nameLabel.leadingAnchor.constraint(
                equalTo: iconView.trailingAnchor,
                constant: 12
            ),
            nameLabel.topAnchor.constraint(
                equalTo: contentView.topAnchor,
                constant: 18
            ),
            nameLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: transferButton.leadingAnchor,
                constant: -12
            ),

            balanceLabel.leadingAnchor.constraint(
                equalTo: nameLabel.leadingAnchor
            ),
            balanceLabel.topAnchor.constraint(
                equalTo: nameLabel.bottomAnchor,
                constant: 4
            ),
            balanceLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: transferButton.leadingAnchor,
                constant: -12
            ),

            transferButton.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -16
            ),
            transferButton.centerYAnchor.constraint(
                equalTo: contentView.centerYAnchor
            ),
            transferButton.widthAnchor.constraint(equalToConstant: 58),
            transferButton.heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    @objc
    private func transferButtonTapped() {
        onTransfer?()
    }
}
