//
//  NicknameSettingView.swift
//  AuthFeature
//
//  Created by 김동현 on 1/16/26.
//

import UIKit
import DSKit

final class NicknameSettingView: UIView {
    
    // MARK: - Dynamic
    private var nextButtonBottonConstraint: NSLayoutConstraint?
    
    // MARK: - UI Component
    private let mainLabel: UILabel = HCLabel(type: .main(text: "사용하실 닉네임을 입력해주세요."))
    private let subLabel: UILabel = HCLabel(type: .sub(text: "닉네임은 언제든지 변경할 수 있어요!"))
    let textField: UITextField = HCTextField(placeholder: "닉네임")
    
    private lazy var hStackView: UIStackView = {
        let st = UIStackView(arrangedSubviews: [
            mainLabel,
            subLabel
        ])
        st.axis = .vertical
        st.spacing = 10
        st.distribution = .fillEqually // 모든 뷰가 동일한 크기
        /// 뷰의 크기를 축 반대 방향으로 꽉 채운다
        /// 세로 스택일 경우, 각 뷰의 가로 너비가 스택의 가로폭에 맞춰진다
        st.alignment = .fill
        return st
    }()
    
    let nextButton: UIButton = HCNextButton(title: "다음")
    
    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupUI()
        setupConstraints()
        
        if let constraint = nextButtonBottonConstraint {
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
        [hStackView, textField, nextButton].forEach {
            self.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    // MARK: - Constraints
    private func setupConstraints() {
        
        nextButtonBottonConstraint = nextButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -10)
        
        NSLayoutConstraint.activate([
            // MARK: - HStack
            hStackView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 30),
            hStackView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 20),
            
            // MARK: - TextField
            textField.topAnchor.constraint(equalTo: hStackView.bottomAnchor, constant: 30),               // y축 위치
            textField.centerXAnchor.constraint(equalTo: safeAreaLayoutGuide.centerXAnchor),               // x축 위치
            textField.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 20), // 좌우 패딩
            textField.heightAnchor.constraint(equalToConstant: 50), // 버튼 높이
            
            // MARK: - NextButton
            nextButton.centerXAnchor.constraint(equalTo: safeAreaLayoutGuide.centerXAnchor),               // x축 위치
            nextButton.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 20), // 좌우패딩
            nextButton.heightAnchor.constraint(equalToConstant: 50),                                       // 버튼높이
            nextButtonBottonConstraint!
        ])
    }
}
    
#if DEBUG
final class NicknameSettingPreviewVC: UIViewController {
    override func loadView() {
        self.view = NicknameSettingView()
    }
}
#endif

#Preview {
    NicknameSettingPreviewVC()
}
