//
//  ProfilePostCell.swift
//  ProfileFeature
//
//  Created by 김동현 on 2/27/26.
//

import UIKit
import Domain
import Kingfisher

public final class ProfilePostCell: UICollectionViewCell {
    
    // 이미지 뷰: 셀의 배경 이미지를 보여준다
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill    // 셀 채우되 비율 유지
        imageView.clipsToBounds = true              // 셀 밖 이미지 자르기
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    func configure(post: Post) {
        let url = URL(string: post.imageURL)
        imageView.kf.setImage(with: url)
    }
}
