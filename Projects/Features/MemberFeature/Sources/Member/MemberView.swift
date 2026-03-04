//
//  MemberView.swift
//  MemberFeature
//
//  Created by 김동현 on 3/4/26.
//

import UIKit
import DSKit

final class MemberView: UIView {
    
    // MARK: - UI Component
    private lazy var memberScrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.showsHorizontalScrollIndicator = false
        scroll.showsVerticalScrollIndicator = true
        return scroll
    }()
    
    lazy var memberStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .leading
        return stack
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "그룹"
        label.font = UIFont.hcFont(.bold, size: 20.scaled)
        label.textColor = .mainWhite
        return label
    }()
    
    private let textLabel: UILabel = {
        let label = HCLabel(type: .main(text: "가족 참여 인원"))
        label.font = .hcFont(.bold, size: 22.scaled)
        return label
    }()
    
    lazy var peopleLabel: UILabel = {
        let label = HCLabel(type: .main(text: "0명"))
        label.font = .hcFont(.bold, size: 22.scaled)
        label.textColor = .hcColor
        return label
    }()
    
    private lazy var titleStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [ textLabel, peopleLabel ])
        stack.axis = .horizontal
        stack.spacing = 5
        stack.alignment = .center
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
        self.backgroundColor = .background
        [titleStack, memberScrollView ].forEach {
            self.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        memberScrollView.addSubview(memberStackView)
        memberStackView.translatesAutoresizingMaskIntoConstraints = false
    }

    // MARK: - Constraints
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // titleStack
            titleStack.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: 40),
            titleStack.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            
            // scrollView
            memberScrollView.topAnchor.constraint(equalTo: titleStack.bottomAnchor, constant: 20),
            memberScrollView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            memberScrollView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),
            memberScrollView.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            
            // stackView inside scrollView
            memberStackView.topAnchor.constraint(equalTo: memberScrollView.topAnchor),
            memberStackView.bottomAnchor.constraint(equalTo: memberScrollView.bottomAnchor),
            memberStackView.leadingAnchor.constraint(equalTo: memberScrollView.leadingAnchor),
            memberStackView.trailingAnchor.constraint(equalTo: memberScrollView.trailingAnchor),
            
            // prevent horizontal scroll
            memberStackView.widthAnchor.constraint(equalTo: memberScrollView.widthAnchor)
        ])
    }
}
