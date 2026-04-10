//
//  CommentBtn.swift
//  Haruhancut
//
//  Created by 김동현 on 6/17/25.
//

import UIKit

/// 댓글 버튼
public final class HCCommentButton: UIButton {
    
    private let leftImageView: UIImageView = {
        let iv = UIImageView()
        iv.tintColor = .white
        iv.contentMode = .scaleAspectFit
        // 나는 최대한 작고 싶어 라는 우선순위 설정
        iv.setContentHuggingPriority(.required, for: .horizontal)
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private lazy var countLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.hcFont(.semiBold, size: 15)
        label.textColor = .mainWhite
        label.backgroundColor = .clear
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var hStack: UIStackView = {
        let hstack = UIStackView(arrangedSubviews: [leftImageView, countLabel])
        hstack.axis = .horizontal
        hstack.spacing = 10
        hstack.alignment = .center
        hstack.isUserInteractionEnabled = false
        hstack.translatesAutoresizingMaskIntoConstraints = false
        return hstack
    }()
    
    public init(image: UIImage, count: Int) {
        super.init(frame: .zero)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.leftImageView.image = image
        self.countLabel.text = String(count)
        makeUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setCount(_ count: Int) {
        countLabel.text = "\(count)"
    }
    
    private func makeUI() {
        self.backgroundColor = .darkGray
        self.layer.cornerRadius = 15
        self.clipsToBounds = true
    }
    
    private func setupConstraints() {
        self.addSubview(hStack)
        NSLayoutConstraint.activate([

            // 위치
            hStack.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            hStack.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            
            // 크기
            hStack.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10)
        ])
    }
}
