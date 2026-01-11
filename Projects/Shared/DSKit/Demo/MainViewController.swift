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
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "title size 20"
        return label
    }()
    
    private lazy var bodyLabel: UILabel = {
        let label = UILabel()
        label.font = .bodyFont
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "body size 15"
        return label
    }()
    
    private lazy var captionLabel: UILabel = {
        let label = UILabel()
        label.font = .captionFont
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "caption size 12"
        return label
    }()
    
    private lazy var hStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, bodyLabel, captionLabel])
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
        label.textColor = .label

        let stack = UIStackView(arrangedSubviews: [colorView, label])
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center

        return stack
    }
    
    private lazy var colorStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            makeColorRow(color: .kakao, name: "kakao"),
            makeColorRow(color: .apple, name: "apple"),
            makeColorRow(color: .mainBlack, name: "mainBlack"),
            makeColorRow(color: .gray300, name: "gray300"),
            makeColorRow(color: .gray900, name: "gray900"),
        ])
        stack.axis = .vertical
        stack.spacing = 12
        return stack
    }()
    
    private lazy var rootStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            hStackView,
            colorStackView
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
        view.backgroundColor = .systemBackground
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
