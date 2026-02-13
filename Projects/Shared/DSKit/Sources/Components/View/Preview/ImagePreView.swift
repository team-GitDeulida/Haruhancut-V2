//  ImagePreViewView.swift
//  Haruhancut
//
//  Created by 김동현 on 6/19/25.
//

import UIKit
import Kingfisher

public final class ImagePreView: UIView {
    
    private let imageURL: String
    
    // MARK: - UI Component
    lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.minimumZoomScale = 1.0
        sv.maximumZoomScale = 3.0
        return sv
    }()

    lazy var imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.backgroundColor = .black
        iv.tintColor = .gray
        return iv
    }()
    
    public lazy var closeButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("닫기", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = .boldSystemFont(ofSize: 18)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    public lazy var saveButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("저장", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = .boldSystemFont(ofSize: 18)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    // MARK: - Initializer
    public init(imageURL: String) {
        self.imageURL = imageURL
        super.init(frame: .zero)
        setupUI()
        setupConstraints()
        loadImage()
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Setup
    private func setupUI() {
        backgroundColor = .black

        [scrollView, closeButton, saveButton].forEach {
            self.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        scrollView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
    }

    // MARK: - Constraints
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // scrollView가 전체 화면을 덮도록
            scrollView.topAnchor.constraint(equalTo: self.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            
            // imageView는 scrollView크기와 동일
            imageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            
            imageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
            

            // 닫기 버튼
            closeButton.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: 20),
            closeButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),
            
            // 저장 버튼
            saveButton.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: 20),
            saveButton.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20)
        ])
    }
    
    private func loadImage() {
        guard let url = URL(string: imageURL) else { return }
        
        // Kingfisher 예시
        imageView.kf.setImage(with: url)
        
        // 만약 라이브러리 안 쓴다면:
        /*
         URLSession.shared.dataTask(with: url) { data, _, _ in
         guard let data,
         let image = UIImage(data: data) else { return }
         
         DispatchQueue.main.async {
         self.imageView.image = image
         }
         }.resume()
         */
    }
}

//#Preview {
//    ImagePreView(image: UIImage())
//}
