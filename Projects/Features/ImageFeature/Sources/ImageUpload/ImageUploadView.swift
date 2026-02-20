//  ImageUploadViewView.swift
//  Haruhancut
//
//  Created by 김동현 on 6/18/25.
//

import UIKit
import DSKit

final class ImageUploadView: UIView {
    
    let image: UIImage
    
    // MARK: - UI Component
    private let cameraView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.layer.cornerRadius = 20
        view.layer.masksToBounds = true
        return view
    }()
    
    // 이미지를 보여줄 이미지 뷰 추가
    private lazy var imageView: UIImageView = {
        let iv = UIImageView(image: image)
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    // 이미지 업로드 버튼
    lazy var uploadButton: HCUploadButton = {
        let button = HCUploadButton(title: "업로드")
        return button
    }()

    // MARK: - Initializer
    init(image: UIImage) {
        self.image = image
        super.init(frame: .zero)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Setup
    private func setupUI() {
        backgroundColor = .background
        [cameraView, uploadButton].forEach {
            self.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        cameraView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
    }

    // MARK: - Constraints
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // 위치
            cameraView.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: 150),
            cameraView.centerXAnchor.constraint(equalTo: self.safeAreaLayoutGuide.centerXAnchor),
            
            // 크기
            cameraView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            cameraView.heightAnchor.constraint(equalTo: cameraView.widthAnchor),
            
            // imageView가 cameraView를 가득 채우도록 설정
            imageView.topAnchor.constraint(equalTo: cameraView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: cameraView.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: cameraView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: cameraView.trailingAnchor),
            
            // uploadButton
            uploadButton.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 40),
            uploadButton.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            uploadButton.widthAnchor.constraint(equalToConstant: 200),
            uploadButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
}

#Preview {
    ImageUploadView(image: UIImage())
}
