//
//  FeedView.swift
//  HomeFeatureV2
//
//  Created by 김동현 on 4/21/26.
//

import UIKit
import DSKit
import Core
import TurboListKit

final class FeedView: UIView {
    private let layoutAdapter: CollectionViewLayoutAdapter

    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(layoutAdapter: layoutAdapter)
        collectionView.backgroundColor = .background
        collectionView.showsVerticalScrollIndicator = false
        collectionView.alwaysBounceVertical = true
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

    init(layoutAdapter: CollectionViewLayoutAdapter) {
        self.layoutAdapter = layoutAdapter
        super.init(frame: .zero)
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
