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
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout:
                UICollectionViewFlowLayout()
        )
        collectionView.backgroundColor = .clear
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

    /// 저장된 피드가 없을 때 첫 조회 중임을 보여 줍니다.
    let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .mainWhite
        indicator.hidesWhenStopped = true
        return indicator
    }()

    /// 최신 피드를 받지 못했을 때 잠깐 보여 주는 안내입니다.
    lazy var noticeLabel: FeedNoticeLabel = {
        let label = FeedNoticeLabel(insets: UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16))
        label.text = LocalizationKey.homeFeedLoadFailed.localized
        label.font = UIFont.hcFont(.medium, size: 14.scaled)
        label.textColor = .mainWhite
        label.backgroundColor = UIColor.black.withAlphaComponent(0.75)
        label.layer.cornerRadius = 16
        label.clipsToBounds = true
        label.alpha = 0
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
        [cameraBtn, bubbleView, collectionView, emptyLabel, loadingIndicator, noticeLabel].forEach {
            addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }

    override func hitTest(
        _ point: CGPoint,
        with event: UIEvent?
    ) -> UIView? {
        let cameraButtonPoint = convert(
            point,
            to: cameraBtn
        )
        if let hitView = cameraBtn.hitTest(
            cameraButtonPoint,
            with: event
        ) {
            return hitView
        }

        return super.hitTest(
            point,
            with: event
        )
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
            emptyLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 320),

            loadingIndicator.centerYAnchor.constraint(equalTo: emptyLabel.centerYAnchor),
            loadingIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),

            noticeLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 12),
            noticeLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            noticeLabel.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, constant: -32)
        ])
    }
}

/// 안쪽 여백이 있는 피드 안내 문구입니다.
final class FeedNoticeLabel: UILabel {
    private let insets: UIEdgeInsets

    init(insets: UIEdgeInsets) {
        self.insets = insets
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + insets.left + insets.right,
            height: size.height + insets.top + insets.bottom
        )
    }
}
