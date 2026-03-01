//  FeedDetailViewView.swift
//  Haruhancut
//
//  Created by 김동현 on 6/19/25.
//

import UIKit
import DSKit
import Domain
import Kingfisher
import Core

final class FeedDetailView: UIView {
    
    var post: Post
    
    var currentImageRenderSize: CGSize {
        imageView.bounds.size
    }
    
    // MARK: - UI Component
    lazy var imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill           // 셀 채우되 비율 유지
        iv.clipsToBounds = true                     // 셀 밖 이미지 자르기
        iv.layer.cornerRadius = 15                  // 모서리 둥글게
        iv.isUserInteractionEnabled = true          // 터치 감지 가능하도록 설정
        iv.backgroundColor = .black
        return iv
    }()
    
    lazy var commentButton: HCCommentButton = {
        let button = HCCommentButton(image: UIImage(systemName: "message")!, count: 0)
        button.uiTestID(UITestID.FeedDetail.commentButton)
        return button
    }()

    // MARK: - Initializer
    init(post: Post) {
        self.post = post
        super.init(frame: .zero)
        setupUI()
        setupConstraints()
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Setup
    private func setupUI() {
        self.backgroundColor = .background
        
        [imageView, commentButton].forEach {
            self.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }

    // MARK: - Constraints
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // MARK: - 이미지
            // 위치
            imageView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: -20),
            
            // 크기
            imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),
            
            // MARK: - 댓글
            // 위치
            commentButton.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            commentButton.trailingAnchor.constraint(equalTo: imageView.trailingAnchor)
        ])
    }
    
    func configure() {
        let url = URL(string: post.imageURL)
        
        let width = UIScreen.main.bounds.width - 40
        let targetSize = CGSize(width: width, height: width)
        guard targetSize != .zero else {
            print("사이즈가 0입니다.")
            return
        }
        
        let processor = DownsamplingImageProcessor(size: targetSize)
        imageView.kf.setImage(
                with: url,
                options: [
                    .processor(processor),
                    .backgroundDecode,
                    .scaleFactor(UIScreen.main.scale)
                ]
            )
    }
}

//#Preview {
//    FeedDetailView(post: Post.samplePosts[0])
//}
