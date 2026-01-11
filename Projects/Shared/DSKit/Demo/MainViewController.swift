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
        stackView.spacing = 16
        return stackView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
    }

    // MARK: - UI Setup
    private func setupUI() {
        self.view.backgroundColor = .systemBackground
        self.view.addSubview(hStackView)
        hStackView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    // MARK: - Constraints
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            hStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            hStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
}

#Preview {
    MainViewController()
}
