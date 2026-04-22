//
//  FeedComponent.swift
//  HomeFeatureV2
//
//  Created by 김동현 on 4/21/26.
//

import UIKit
import CarbonListKit
import Kingfisher
import DSKit
import Domain

struct FeedComponent: ListComponent {
    typealias Content = Post
    typealias View = FeedRowView
    let content: Post
    
    init(post: Post) {
        self.content = post
    }
    
    func makeView(context: ListComponentContext<Void>) -> FeedRowView {
        FeedRowView()
    }
    
    func updateView(_ view: FeedRowView, context: ListComponentContext<Void>) {
        view.configure(post: content)
    }
    
    func height(context: ListComponentHeightContext) -> ListComponentHeight {
        return .absolute(context.containerWidth + 50)
    }
}

extension FeedComponent: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.content == rhs.content
    }
}

final class FeedRowView: UIView {
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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
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
            
            nicknameLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 14),
            nicknameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            
            timeLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 14),
            timeLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
//            timeLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
    }
    
    func configure(post: Post) {
        nicknameLabel.text = post.nickname
        timeLabel.text = post.createdAt.toRelativeString()
        imageView.kf.setImage(with: URL(string: post.imageURL))
    }
}
