//
//  SignInView.swift
//  AuthFeature
//
//  Created by 김동현 on 1/13/26.
//

import UIKit
import DSKit
import ThirdPartyLibs

final class SignInView: UIView {
    
    let animationView = HCLottieView(animationName: "LottieCamera")
    
    lazy var kakaoLoginButton = SocialLoginButton(type: .kakao,
                                                  title: "카카오로 계속하기")
    
    lazy var appleLoginButton = SocialLoginButton(type: .apple,
                                                  title: "Apple로 계속하기")
    
    private lazy var stackView: UIStackView = {
        let st = UIStackView(arrangedSubviews: [
            kakaoLoginButton,
            appleLoginButton
        ])
        st.axis = .vertical
        st.spacing = 10
        st.distribution = .fillEqually
        st.alignment = .fill
        return st
    }()

    private lazy var titleLabel = HCLabel(type: .custom(text: "하루한컷",
                                              font: .logoFont,
                                              color: .mainWhite))

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
        [animationView, stackView, titleLabel].forEach {
            self.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    // MARK: - Constraints
    private func setupConstraints() {
        // let topConstant: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 120 : 220
        NSLayoutConstraint.activate([
            
            // MARK: - Lottie
            // 위치
            animationView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -50.scaled),
            animationView.centerXAnchor.constraint(equalTo: centerXAnchor),
            
            // 크기
            animationView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20.scaled),
            animationView.heightAnchor.constraint(equalToConstant: 200.scaled),
            
            // MARK: - StackView
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -50.scaled),
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20.scaled),
            stackView.heightAnchor.constraint(equalToConstant: 130.scaled),
            
            // MARK: - Title
            titleLabel.topAnchor.constraint(equalTo: animationView.bottomAnchor, constant: 20.scaled),
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
    }
}

//#Preview {
//    SignInViewController(viewModel: StubAuthViewModel())
//}
