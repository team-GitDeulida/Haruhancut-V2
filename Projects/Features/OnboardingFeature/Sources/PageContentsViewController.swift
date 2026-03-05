//
//  PageContentsViewController.swift
//  Onboarding
//
//  Created by 김동현 on 
//

import UIKit
import DSKit

final class PageContentsViewController: UIViewController {
    
    // MARK: - UI Component
    private lazy var stackView: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [imageView, titleLabel, subTitleLabel])
        sv.axis = .vertical
        sv.spacing = 14.scaled
        sv.alignment = .center
        return sv
    }()
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .hcFont(.extraBold, size: 30)
        label.textColor = .black
        return label
    }()
    private let subTitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .hcFont(.light, size: 20.scaled)
        return label
    } ()
    
    // MARK: - Initializer
    init(image: UIImage, title: String, subTitle: String) {
        super.init(nibName: nil, bundle: nil)
        imageView.image = image
        titleLabel.text = title
        subTitleLabel.text = subTitle
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        makeUI()
        constraints()
    }

    // MARK: - UI Setting
    private func makeUI() {
        view.backgroundColor = .white
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.setCustomSpacing(20.scaled, after: imageView)
    }
    
    private func constraints() {
        NSLayoutConstraint.activate([
            
            // stackView - 중앙 정렬 + 좌우 여백
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20.scaled),
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -10.scaled),  // inset 50 * 2
            
            // imageView - view 기준으로 60%
            imageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.6),
            imageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.6)
            
        ])
    }
}
