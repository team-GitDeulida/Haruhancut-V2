//
//  SocialLoginButton.swift
//  DSKit
//
//  Created by 김동현 on 1/12/26.
//

import UIKit

public final class SocialLoginButton: UIButton {

    public enum LoginType {
        case kakao, apple
    }
    
    public init(type: LoginType, title: String) {
        super.init(frame: .zero)
        self.configure(type: type, title: title)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configure(type: LoginType, title: String) {
        var config = UIButton.Configuration.filled()
        config.imagePlacement = .leading
        config.imagePadding = 20.scaled
        config.title = title
        config.baseBackgroundColor = .black
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.hcFont(.semiBold, size: 16)
            return outgoing
        }
        
        switch type {
        case .kakao:
            config.image = UIImage(
                named: "Logo Kakao",
                in: .module, // 자기 자신의 번들
                compatibleWith: nil
            )
            config.baseForegroundColor = .mainBlack

        case .apple:
            // UIImage(named: "Logo Kakao")
            config.image = UIImage(
                named: "Logo Apple",
                in: .module,
                compatibleWith: nil
            )
            config.baseForegroundColor = .mainBlack
        }
        
        self.configuration = config
        self.layer.cornerRadius = 20
        self.clipsToBounds = true
        
        /// Pressed Animation
        self.configurationUpdateHandler = { button in
            var config = button.configuration
            switch type {
            case .kakao:
                config?.baseBackgroundColor = button.isHighlighted ? .kakaoTapped : .kakao
            case .apple:
                config?.baseBackgroundColor = button.isHighlighted ? .appleTapped : .apple
            }
            button.configuration = config
        }
    }
}

#Preview {
    SocialLoginButton(type: .kakao, title: "카카오로 계속하기")
}
