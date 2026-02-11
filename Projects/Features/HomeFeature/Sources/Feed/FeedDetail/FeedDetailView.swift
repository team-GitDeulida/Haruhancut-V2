//  FeedDetailViewView.swift
//  Haruhancut
//
//  Created by 김동현 on 6/19/25.
//

import UIKit
import DSKit
import Domain

final class FeedDetailView: UIView {
    
    var post: Post
    
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
        return button
    }()

    // MARK: - Initializer
    init(post: Post) {
        self.post = post
        super.init(frame: .zero)
        setupUI()
        setupConstraints()
        configure(post: post)
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
    
    func configure(post: Post) {
        let url = URL(string: post.imageURL)
        imageView.kf.setImage(with: url)
    }
}

//#Preview {
//    FeedDetailView(post: Post.samplePosts[0])
//}
