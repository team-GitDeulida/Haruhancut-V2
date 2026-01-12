//
//  MainViewController.swift
//  DSKitDemo
//
//  Created by 김동현 on 
//

import UIKit
import DSKit

final class MainViewController: UIViewController {
    
    // MARK: - UI Component
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .titleFont
        label.textColor = .black
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "title size 20"
        return label
    }()
    
    private lazy var bodyLabel: UILabel = {
        let label = UILabel()
        label.font = .bodyFont
        label.textColor = .black
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "body size 15"
        return label
    }()
    
    private lazy var captionLabel: UILabel = {
        let label = UILabel()
        label.font = .captionFont
        label.textColor = .black
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "caption size 12"
        return label
    }()
    
    private lazy var hStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            titleLabel,
            bodyLabel,
            captionLabel,
            SocialLoginButton(type: .kakao, title: "카카오로 계속하기"),
            SocialLoginButton(type: .apple, title: "애플로 계속하기")
        ])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 10
        return stackView
    }()
    
    // MARK: - Color
    private func makeColorRow(
        color: UIColor,
        name: String
    ) -> UIView {

        let colorView = UIView()
        colorView.backgroundColor = color
        colorView.layer.cornerRadius = 8
        colorView.translatesAutoresizingMaskIntoConstraints = false
        colorView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        colorView.heightAnchor.constraint(equalToConstant: 40).isActive = true

        let label = UILabel()
        label.text = name
        label.font = .bodyFont
        label.textColor = .black

        let stack = UIStackView(arrangedSubviews: [colorView, label])
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center

        return stack
    }
    
    private lazy var leftColorColumn: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            makeColorRow(color: .kakao, name: "kakao"),
            makeColorRow(color: .kakaoTapped, name: "kakaoTapped"),
            makeColorRow(color: .apple, name: "apple"),
            makeColorRow(color: .appleTapped, name: "appleTapped"),

            makeColorRow(color: .background, name: "background"),
            makeColorRow(color: .mainBlack, name: "mainBlack"),
            makeColorRow(color: .mainWhite, name: "mainWhite"),
            makeColorRow(color: .buttonTapped, name: "buttonTapped"),
            makeColorRow(color: .hcColor, name: "hcColor"),
        ])
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .leading
        return stack
    }()

    private lazy var rightColorColumn: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            makeColorRow(color: .gray000, name: "gray000"),
            makeColorRow(color: .gray100, name: "gray100"),
            makeColorRow(color: .gray200, name: "gray200"),
            makeColorRow(color: .gray300, name: "gray300"),
            makeColorRow(color: .gray500, name: "gray500"),
            makeColorRow(color: .gray700, name: "gray700"),
            makeColorRow(color: .gray900, name: "gray900"),
        ])
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .leading
        return stack
    }()

    private lazy var colorGridStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            leftColorColumn,
            rightColorColumn
        ])
        stack.axis = .horizontal
        stack.spacing = 32
        stack.alignment = .top
        return stack
    }()
    
    private lazy var colorStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            makeColorRow(color: .kakao, name: "kakao"),
            makeColorRow(color: .kakaoTapped, name: "kakaoTapped"),
            makeColorRow(color: .apple, name: "apple"),
            makeColorRow(color: .appleTapped, name: "appleTapped"),
            
            makeColorRow(color: .background, name: "background"),
            makeColorRow(color: .mainBlack, name: "mainBlack"),
            makeColorRow(color: .mainWhite, name: "mainWhite"),
            makeColorRow(color: .buttonTapped, name: "buttonTapped"),
            makeColorRow(color: .hcColor, name: "hcColor"),
            
            makeColorRow(color: .gray000, name: "gray000"),
            makeColorRow(color: .gray100, name: "gray100"),
            makeColorRow(color: .gray200, name: "gray200"),
            makeColorRow(color: .gray300, name: "gray300"),
            makeColorRow(color: .gray500, name: "gray500"),
            makeColorRow(color: .gray700, name: "gray700"),
            makeColorRow(color: .gray900, name: "gray900"),
        ])
        
        stack.axis = .vertical
        stack.spacing = 12
        return stack
    }()
    
    private lazy var rootStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            hStackView,
            colorGridStackView
        ])
        stack.axis = .vertical
        stack.spacing = 32
        stack.alignment = .center
        return stack
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
    }

    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .gray000
        view.addSubview(rootStackView)
        rootStackView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    // MARK: - Constraints
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            rootStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            rootStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
}

#Preview {
    MainViewController()
}
