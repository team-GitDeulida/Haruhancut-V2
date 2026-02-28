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
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        imageView.kf.cancelDownloadTask() // 다운로드 취소
        imageView.image = nil             // 기존 비트맵 이미지 제거
    }
    
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
    
    func configure(post: Post, targetSize: CGSize) {
        let url = URL(string: post.imageURL)
        
        // let targetSize = contentView.bounds.size
        let processor = DownsamplingImageProcessor(size: targetSize)
        imageView.kf.setImage(
            with: url,
            options: [
                .processor(processor),             // 다운샘플링으로 픽셀 수를 줄임
                .backgroundDecode,                 // 디코딩 백그라운드 실행
                .scaleFactor(UIScreen.main.scale), // 디스플레이 스케일에 맞게 이미지 처리
                // .cacheOriginalImage             // 원본 이미지를 디스크 캐시에 저장
            ]
        ) { result in
            switch result {
            case .failure(let error):
                print("Kingfisher error:", error)
            case .success:
                break
            }
        }
    }
}
