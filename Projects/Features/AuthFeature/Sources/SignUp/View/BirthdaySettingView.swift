//
//  BirthdaySettingView.swift
//  AuthFeature
//
//  Created by 김동현 on 1/17/26.
//

import UIKit
import DSKit

final class BirthdaySettingView: UIView {
    
    // MARK: - UI Component
    private lazy var mainLabel: UILabel = HCLabel(type: .main(text: ""))
    private lazy var subLabel: UILabel = HCLabel(type: .sub(text: LocalizationKey.authSignupBirthdaySubtitle.localized))
    lazy var textField: UITextField = HCTextField(placeholder: LocalizationKey.authSignupBirthdayPlaceholder.localized)
    private lazy var hStackView: UIStackView = {
        let st = UIStackView(arrangedSubviews: [
            mainLabel,
            subLabel
        ])
        st.spacing = 10
        st.axis = .vertical
        st.distribution = .fill
        // 뷰의 크기를 축 반대 방향으로 꽉 채운다
        // 세로 스택일 경우, 각 뷰의 가로 너비가 스택의 가로폭에 맞춰진다
        st.alignment = .fill
        return st
    }()
    let nextButton: UIButton = HCNextButton(title: LocalizationKey.authSignupBirthdayDone.localized)
    let datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .wheels
        picker.locale = .autoupdatingCurrent
        picker.timeZone = .autoupdatingCurrent
        return picker
    }()

    // MARK: - Initializer
    init() {
        super.init(frame: .zero)
        setupUI()
        setupConstraints()
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
        NSLayoutConstraint.activate([
            // MARK:  hStack
            hStackView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 30),
            hStackView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 20),
            hStackView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -20),
            
            // MARK: - textField
            textField.topAnchor.constraint(equalTo: hStackView.bottomAnchor, constant: 30),  // y축 위치
            textField.centerXAnchor.constraint(equalTo: safeAreaLayoutGuide.centerXAnchor), // x축 위치
            textField.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 20), // 좌우 패딩
            textField.heightAnchor.constraint(equalToConstant: 50), // 버튼 높이
            
            // MARK: - NextBtn
            nextButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -10),
            nextButton.centerXAnchor.constraint(equalTo: safeAreaLayoutGuide.centerXAnchor),
            nextButton.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 20),// 좌우 패딩
            nextButton.heightAnchor.constraint(equalToConstant: 50), // 버튼 높이
                   
        ])
    }
    
    func updateNickname(nickname: String) {
        mainLabel.text = String(format: LocalizationKey.authSignupBirthdayTitleFormat.localized, nickname)
    }
}
