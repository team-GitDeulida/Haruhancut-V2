//
//  NicknameEditView.swift
//  ProfileFeature
//
//  Created by 김동현 on 3/3/26.
//

import UIKit
import DSKit

final class NicknameEditView: UIView {
    
    // MARK: - UI Component
    private let mainLabel: UILabel = HCLabel(type: .main(text: LocalizationKey.profileNicknameEditTitle.localized))
    private let subLabel: UILabel = HCLabel(type: .sub(text: LocalizationKey.profileNicknameEditSubtitle.localized))
    lazy var textField: UITextField = HCTextField(placeholder: LocalizationKey.profileNicknameEditPlaceholder.localized)
    private lazy var hStackView: UIStackView = {
        let st = UIStackView(arrangedSubviews: [
            mainLabel,
            subLabel,
        ])
        st.spacing = 10
        st.axis = .vertical
        st.distribution = .fillEqually // 모든 뷰가 동일한 크기
        // 뷰의 크기를 축 반대 방향으로 꽉 채운다
        // 세로 스택일 경우, 각 뷰의 가로 너비가 스택의 가로폭에 맞춰진다
        st.alignment = .fill
        return st
    }()
    lazy var endButton: UIButton = {
        let button = HCNextButton(title: LocalizationKey.profileNicknameEditComplete.localized)
        return button
    }()

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }
    
    // 외부 터치 시 키보드 내리기
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        endEditing(true)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Setup
    private func setupUI() {
        backgroundColor = .background
        [hStackView, textField, endButton].forEach {
            self.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }

    // MARK: - Constraints
    private func setupConstraints() {
        
        NSLayoutConstraint.activate([
            // hStackView
            hStackView.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: 30),
            hStackView.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            
            // textField
            textField.topAnchor.constraint(equalTo: hStackView.bottomAnchor, constant: 30),
            textField.centerXAnchor.constraint(equalTo: self.safeAreaLayoutGuide.centerXAnchor),
            textField.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            textField.heightAnchor.constraint(equalToConstant: 50),
            
            // endButton
            endButton.centerXAnchor.constraint(equalTo: self.safeAreaLayoutGuide.centerXAnchor),
            endButton.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            endButton.heightAnchor.constraint(equalToConstant: 50),
            
            // 키보드에 자동 반응
            endButton.bottomAnchor.constraint(
                equalTo: keyboardLayoutGuide.topAnchor,
                constant: -10
            )
        ])
    }
}

#Preview {
    NicknameEditView()
}
