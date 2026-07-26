//
//  FeedComponent.swift
//  HomeFeatureV3
//
//  Created by 김동현 on 4/26/26.
//

import CollectionViewAdapter
import Domain
import UIKit
import DSKit
import Kingfisher

struct FeedComponent: Component, Equatable {
    typealias Item = FeedRowView.Item

    let post: Post
    let item: Item

    init(post: Post) {
        self.post = post
        item = .init(post: post)
    }

    var estimatedHeight: CGFloat {
        240
    }

    func createContent() -> FeedRowView {
        FeedRowView()
    }

    func render(
        context _: ComponentContext,
        content: FeedRowView
    ) {
        content.item = item
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.item == rhs.item
    }
}

final class FeedRowView: UIView, Touchable {

    struct Item: Identifiable, Equatable {
        let id: String
        let nickname: String
        let imageURL: String
        let relativeTimeText: String

        init(post: Post) {
            id = post.postId
            nickname = post.nickname
            imageURL = post.imageURL
            relativeTimeText =
                post.createdAt.toRelativeString()
        }
    }

    var item: Item? {
        didSet {
            guard item != oldValue else {
                return
            }
            applyItem()
        }
    }

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 15
        iv.backgroundColor = .tertiarySystemFill
        return iv
    }()

    private let nicknameLabel: HCLabel = {
        HCLabel(type: .feedNickname(text: LocalizationKey.commonPreviewNickname.localized))
    }()

    private let timeLabel: HCLabel = {
        HCLabel(type: .feedTime(text: LocalizationKey.commonPreviewRelativeTime.localized))
    }()

    private let bottomSpacing: CGFloat = 14

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        enablePressedEffect()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        [imageView, nicknameLabel, timeLabel].forEach {
            addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),

            nicknameLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: bottomSpacing),
            nicknameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            nicknameLabel.bottomAnchor.constraint(equalTo: bottomAnchor),

            timeLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: bottomSpacing),
            timeLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            timeLabel.leadingAnchor.constraint(greaterThanOrEqualTo: nicknameLabel.trailingAnchor, constant: 8),
            timeLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        autoLayoutFittingSize(for: size)
    }

    private func applyItem() {
        imageView.kf.cancelDownloadTask()
        imageView.image = nil

        guard let item else {
            nicknameLabel.text = nil
            timeLabel.text = nil
            accessibilityLabel = nil
            return
        }

        nicknameLabel.text = item.nickname
        timeLabel.text = item.relativeTimeText
        imageView.kf.setImage(
            with: URL(string: item.imageURL)
        )
        accessibilityLabel =
            "\(item.nickname), \(item.relativeTimeText)"
    }
}

private extension UIView {
    func autoLayoutFittingSize(
        for size: CGSize,
        targetWidth: CGFloat? = nil,
        minimumHeight: CGFloat = 0
    ) -> CGSize {
        // UICollectionView가 준 폭을 기준으로, 오토레이아웃이 계산한 최소 높이를 구한다.
        let targetWidth = max(targetWidth ?? size.width, 1)
        let fittingSize = CGSize(
            width: targetWidth,
            height: UIView.layoutFittingCompressedSize.height
        )
        // 가로는 고정하고 세로만 유연하게 계산해서 콘텐츠에 맞는 실제 높이를 얻는다.
        let result = systemLayoutSizeFitting(
            fittingSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        // 소수점 높이를 올림 처리하고, 필요하면 최소 높이를 보장한다.
        return CGSize(
            width: targetWidth,
            height: max(ceil(result.height), minimumHeight)
        )
    }
}

#Preview {
    FeedRowView()
}
