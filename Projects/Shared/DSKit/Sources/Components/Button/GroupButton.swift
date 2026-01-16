//
//  GroupButton.swift
//  DSKit
//
//  Created by 김동현 on 1/16/26.
//

import UIKit

/// 그룹 버튼
public final class HCGroupButton: UIButton {
    
    public init(topText: String, bottomText: String, rightImage: String) {
        super.init(frame: .zero)
        self.mainLabel.text = topText
        self.subLabel.text = bottomText
        rightImageView.image = UIImage(systemName: rightImage)
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var mainLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.hcFont(.semiBold, size: 15)
        label.textColor = .gray
        label.backgroundColor = .clear
        return label
    }()
    
    private lazy var subLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.hcFont(.bold, size: 20)
        label.textColor = .mainWhite
        label.backgroundColor = .clear
        return label
    }()
    
    /// 바로 초기화
    private let rightImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .white
        // 이미지 비율을 유지한 채, View 영역 안에 맞춤
        imageView.contentMode = .scaleAspectFit
        /*
         가로 방향에서 자신이 최대한 줄어들고 싶다고 우선순위를 줌
         [UILabel][UIImageView]  ← 이런 구조일 때
         label은 최대한 넓게, imageView는 아이콘만큼만 표시됨
        */
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var labelStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            mainLabel,
            subLabel,
        ])
        stack.spacing = 10
        stack.axis = .vertical
        stack.isUserInteractionEnabled = false
        stack.backgroundColor = .clear
        stack.distribution = .fillEqually
        stack.alignment = .fill
        return stack
    }()
    
    private lazy var hStack: UIStackView = {
        let hstack = UIStackView(arrangedSubviews: [labelStackView, UIView(), rightImageView])
        hstack.axis = .horizontal
        hstack.spacing = 10
        hstack.alignment = .center
        hstack.translatesAutoresizingMaskIntoConstraints = false
        hstack.isUserInteractionEnabled = false // ✅ 터치 이벤트 가로채지 않도록
        return hstack
    }()
    
    private func configure() {
        var config = UIButton.Configuration.plain()
        config.baseBackgroundColor = .gray500
        config.background.backgroundColor = .gray500
        
        self.configuration = config
        self.layer.cornerRadius = 10
        self.clipsToBounds = true
        
        self.configurationUpdateHandler = { button in
            var config = button.configuration
            config?.baseBackgroundColor = button.isHighlighted ? .black : .gray500
            config?.background.backgroundColor = button.isHighlighted ? .gray700 : .gray500
            button.configuration = config
        }

        
        self.addSubview(hStack)
        NSLayoutConstraint.activate([
            hStack.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            hStack.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),
            hStack.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
    }
}
