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
        label.text = "하루한컷"
        label.font = UIFont.hcFont(.bold, size: 20)
        label.textColor = .mainWhite
        return label
    }()
    
    private lazy var mainLabel: UILabel = {
        let label = UILabel()
        label.text = "가족에게 받은\n그룹 초대 코드가 있으신가요?"
        label.numberOfLines = 0
        label.textColor = .mainWhite
        label.font = UIFont.hcFont(.bold, size: 20)
        return label
    }()
    
    // 입장 label
    lazy var enterButton: HCGroupButton = {
        let button = HCGroupButton(
            topText: "초대 코드를 받았다면",
            bottomText: "가족 방 입장하기",
            rightImage: "arrow.right")
        return button
    }()
    
    // 초대 label
    lazy var hostButton: UIButton = {
        let button = HCGroupButton(
            topText: "초대 코드가 없다면",
            bottomText: "가족 방 만들기",
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
