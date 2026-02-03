//
//  GroupSelectView.swift
//  AuthFeature
//
//  Created by 김동현 on 2/3/26.
//

import UIKit
import DSKit

final class GroupHostView: UIView {
    
    // MARK: - Dynamic
    private var btnDynamincConstraint: NSLayoutConstraint?
    
    // MARK: - UI Component
    private lazy var mainLabel: HCLabel = {
        let label = HCLabel(type: .main(text: "그룹 이름을 입력해 주세요"))
        return label
    }()
    
    lazy var textField: HCTextField = {
        let textField = HCTextField(placeholder: "그룹 이름을 입력해 주세요")
        return textField
    }()
    
    lazy var endButton: HCNextButton = {
        let button = HCNextButton(title: "완료")
        return button
    }()

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        
        if let constraint = btnDynamincConstraint {
            self.bindKeyboard(to: constraint)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Setup
    private func setupUI() {
        backgroundColor = .background
        
        [mainLabel, textField, endButton].forEach {
            self.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

    }

    // MARK: - Constraints
    private func setupConstraints() {
        
        btnDynamincConstraint = endButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -10)
        
        NSLayoutConstraint.activate([
            // MARK: - mainLabel
            mainLabel.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: 30),
            mainLabel.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            
            // MARK: - textField
            textField.topAnchor.constraint(equalTo: mainLabel.bottomAnchor, constant: 30),
            textField.centerXAnchor.constraint(equalTo: self.safeAreaLayoutGuide.centerXAnchor),
            textField.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            textField.heightAnchor.constraint(equalToConstant: 50),
            
            // MARK: - endButton
            endButton.centerXAnchor.constraint(equalTo: self.safeAreaLayoutGuide.centerXAnchor),
            endButton.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            endButton.heightAnchor.constraint(equalToConstant: 50),
            btnDynamincConstraint!
        ])
    }
}

