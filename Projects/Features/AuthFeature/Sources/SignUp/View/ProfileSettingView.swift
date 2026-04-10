//
//  ProfileSettingView.swift
//  AuthFeature
//
//  Created by 김동현 on 1/17/26.
//

import UIKit
import DSKit
import RxCocoa

final class ProfileSettingView: UIView {
    
    // MARK: - Properties
    var onRequestPresentImagePicker: ((UIImagePickerController.SourceType) -> Void)?
    
    // MARK: - UIImageView Rx화
    // - UIImageView는 rx.image같은 Observable이 없어서 이미지 선택 시 emit하는 스트림을 직접 구현해야 함
    // - updateProfileImage()에서 profileImageRelay.accept(image) 해주자
    let profileImageRelay = BehaviorRelay<UIImage?>(value: nil)
    
    // MARK: - UI Component
    private lazy var mainLabel: UILabel = HCLabel(type: .main(text: ""))
    private lazy var subLabel: UILabel = HCLabel(type: .sub(text: LocalizationKey.authSignupProfileSubtitle.localized))
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
    
    lazy var profileImageView: ProfileImageView = {
        let imageView = ProfileImageView(size: 100, iconSize: 60)
        imageView.onCameraTapped = { [weak self] in
            guard let self = self else { return }
            self.onRequestPresentImagePicker?(.photoLibrary)
        }
        return imageView
    }()
    
    lazy var nextButton: UIButton = HCNextButton(title: LocalizationKey.authSignupProfileDone.localized)
    
    let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.color = .lightGray
        return indicator
    }()
    
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
        
        [hStackView, profileImageView, nextButton, activityIndicator].forEach {
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
            
            // MARK: - ProfileImage
            profileImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            profileImageView.centerXAnchor.constraint(equalTo: self.safeAreaLayoutGuide.centerXAnchor),
            
            
            // MARK: - NextBtn
            nextButton.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            nextButton.centerXAnchor.constraint(equalTo: self.safeAreaLayoutGuide.centerXAnchor),
            nextButton.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            nextButton.heightAnchor.constraint(equalToConstant: 50),
        
            // MARK: - Indicator
            activityIndicator.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
    }
}

extension ProfileSettingView {
    func updateNickname(nickname: String) {
        mainLabel.text = String(format: LocalizationKey.authSignupProfileTitleFormat.localized, nickname)
    }
    
    func updateProfileImage(_ image: UIImage) {
        profileImageView.setImage(image)
        profileImageRelay.accept(image)
    }
}
