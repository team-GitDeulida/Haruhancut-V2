//
//  FeedView.swift
//  HomeFeatureV2
//
//  Created by 김동현 on 4/21/26.
//

import UIKit
import DSKit
import Core

final class FeedView: UIView {

    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = .init(top: 16, left: 16, bottom: 16, right: 16)
        layout.minimumInteritemSpacing = 16
        layout.minimumLineSpacing = 16

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .background
        collectionView.showsVerticalScrollIndicator = false
        collectionView.accessibilityIdentifier = UITestID.Feed.collectionView
        return collectionView
    }()

    let bubbleView = BubbleView(text: LocalizationKey.homeFeedBubbleAddPhoto.localized)

    lazy var cameraBtn: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "button.programmable"), for: .normal)
        button.tintColor = .mainWhite
        button.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 70.scaled), forImageIn: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.uiTestID(UITestID.Feed.cameraButton)
        return button
    }()

    lazy var emptyLabel: UILabel = {
        let label = UILabel()
        label.text = LocalizationKey.homeDescription.localized
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = UIFont.hcFont(.medium, size: 20.scaled)
        label.textColor = .mainWhite
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .background
        [collectionView, cameraBtn, bubbleView, emptyLabel].forEach {
            addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),

            cameraBtn.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -50),
            cameraBtn.centerXAnchor.constraint(equalTo: centerXAnchor),

            bubbleView.bottomAnchor.constraint(equalTo: cameraBtn.topAnchor, constant: -10),
            bubbleView.centerXAnchor.constraint(equalTo: centerXAnchor),

            emptyLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -50),
            emptyLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            emptyLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 320)
        ])
    }
}
