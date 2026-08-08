//
//  FeedDetailView.swift
//  HomeFeatureV2
//
//  Created by 김동현 on 4/22/26.
//

import UIKit
import DSKit
import Kingfisher
import Core

final class FeedDetailView: UIView {

    private var currentImageURL: String?

    var currentImageRenderSize: CGSize {
        imageView.bounds.size
    }

    lazy var imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 15
        iv.isUserInteractionEnabled = true
        iv.backgroundColor = .black
        return iv
    }()

    lazy var commentButton: HCCommentButton = {
        let button = HCCommentButton(image: UIImage(systemName: "message")!, count: 0)
        button.uiTestID(UITestID.FeedDetail.commentButton)
        return button
    }()

    init() {
        super.init(frame: .zero)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        self.backgroundColor = .background

        [imageView, commentButton].forEach {
            self.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: -20),
            imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),
            commentButton.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            commentButton.trailingAnchor.constraint(equalTo: imageView.trailingAnchor)
        ])
    }

    func configure(
        imageURL: String,
        initialImage: UIImage?
    ) {
        guard currentImageURL != imageURL else { return }

        guard let url = URL(string: imageURL) else {
            currentImageURL = nil
            imageView.kf.cancelDownloadTask()
            imageView.image = nil
            return
        }

        imageView.kf.cancelDownloadTask()
        currentImageURL = imageURL
        imageView.image = initialImage

        imageView.kf.setImage(
            with: url,
            options: [
                .backgroundDecode,
                .scaleFactor(UIScreen.main.scale),
                .keepCurrentImageWhileLoading
            ]
        ) { [weak self] result in
            guard case .failure = result,
                  self?.currentImageURL == imageURL
            else {
                return
            }
            self?.currentImageURL = nil
        }
    }
}
