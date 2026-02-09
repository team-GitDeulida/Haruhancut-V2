//
//  FeedCell.swift
//  HomeFeature
//
//  Created by 김동현 on 2/9/26.
//

import UIKit
import Kingfisher
import DSKit
import Domain

final class FeedCell: UICollectionViewCell {
    
    // MARK: - UI
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill           // 셀 채우되 비율 유지
        iv.clipsToBounds = true                     // 셀 밖 이미지 자르기
        iv.layer.cornerRadius = 15                  // 모서리 둥글게
        return iv
    }()
    
    private let nicknameLabel: HCLabel = {
        let label = HCLabel(type: .feedNickname(text: "홍길동"))
        return label
    }()
    
    private let timeLabel: HCLabel = {
        let label = HCLabel(type: .feedTime(text: "1분 전"))
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
    
    // MARK: - UI Setup
    private func setupUI() {
        [imageView, nicknameLabel, timeLabel].forEach {
            contentView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    // MARK: - Constraints
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // imageView(정사각형)
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, constant: 0),
            
            // nickname
            nicknameLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 14),
            nicknameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            
            // time
            timeLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 14),
            timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8)
        ])
    }
    
    // 외부에서 데이터 받아 셀 구성
    func configure(post: Post) {
        nicknameLabel.text = post.nickname
        timeLabel.text = post.createdAt.toRelativeString()
        
        let url = URL(string: post.imageURL)
        imageView.kf.setImage(with: url)
    }
}
