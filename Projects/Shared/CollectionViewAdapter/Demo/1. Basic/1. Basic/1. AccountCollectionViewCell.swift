//
//  AccountCollectionViewCell.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/21/26.
//

import UIKit

final class AccountCollectionViewCell: UICollectionViewCell {
    
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
    
    /**
     - 일반적으로 함수 파라미터로 받은 클로저는 함수가 실행되는 동안에만 사용되는 non-escaping 클로저
     - onTransfer를 함수 안에서 즉시 실행하지 않고 프로퍼티에 저장해 버튼을 누르는 미래 시점에 실행하기 때문에 @escaping을 사용합니다.
     */
    func configure(
        account: BankAccount,
        onTransfer: @escaping () -> Void
    ) {
        nameLabel.text = account.name
        balanceLabel.text = account.balanceText
        self.onTransfer = onTransfer
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
