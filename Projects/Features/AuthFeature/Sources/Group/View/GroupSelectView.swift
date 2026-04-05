//
//  GroupSelectView.swift
//  AuthFeature
//
//  Created by 김동현 on 2/3/26.
//

import UIKit
import DSKit

final class GroupSelectView: UIView {
    
    // MARK: - UI Component
    let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "auth.signin.app_name".localized()
        label.font = UIFont.hcFont(.bold, size: 20)
        label.textColor = .mainWhite
        return label
    }()
    
    private lazy var mainLabel: UILabel = {
        let label = UILabel()
        label.text = "auth.group.select.title".localized()
        label.numberOfLines = 0
        label.textColor = .mainWhite
        label.font = UIFont.hcFont(.bold, size: 20)
        return label
    }()
    
    // 입장 label
    lazy var enterButton: HCGroupButton = {
        let button = HCGroupButton(
            topText: "auth.group.select.enter.top".localized(),
            bottomText: "auth.group.select.enter.bottom".localized(),
            rightImage: "arrow.right")
        return button
    }()
    
    // 초대 label
    lazy var hostButton: UIButton = {
        let button = HCGroupButton(
            topText: "auth.group.select.host.top".localized(),
            bottomText: "auth.group.select.host.bottom".localized(),
            rightImage: "arrow.right")
        return button
    }()
    
    // 입장초대 viewStack
    private lazy var hStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            enterButton,
            hostButton
        ])
        stack.spacing = 20
        stack.axis = .vertical
        stack.distribution = .fillEqually
        stack.alignment = .fill
        return stack
    }()

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Setup
    private func setupUI() {
        backgroundColor = .background
        
        [mainLabel, hStackView].forEach {
            self.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

    }

    // MARK: - Constraints
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // MARK: - mainLabel
            mainLabel.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: 30),
            mainLabel.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            
            // MARK: - hStack
            // 위치
            hStackView.topAnchor.constraint(equalTo: mainLabel.bottomAnchor, constant: 50),
            hStackView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            
            // 크기
            hStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            hStackView.heightAnchor.constraint(equalToConstant: 200)
        ])
    }
}

#Preview {
    GroupView()
}
