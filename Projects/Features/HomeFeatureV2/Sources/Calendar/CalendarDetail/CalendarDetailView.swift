//
//  CalendarDetailView.swift
//  HomeFeatureV2
//
//  Created by 김동현 on 4/22/26.
//

import UIKit
import Domain
import DSKit

final class CalendarDetailView: UIView {
    
    var posts: [Post]
    var selectedDate: String
    var currentIndex: Int = 0
    
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 40
        layout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.isPagingEnabled = true
        view.showsHorizontalScrollIndicator = false
        view.backgroundColor = .background
        view.register(CalendarDetailCell.self, forCellWithReuseIdentifier: CalendarDetailCell.reuseIdentifier)
        return view
    }()
    
    lazy var closeButton: UIButton = {
        let btn = UIButton()
        btn.setTitle(LocalizationKey.commonClose.localized, for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = .boldSystemFont(ofSize: 18)
        return btn
    }()
    
    lazy var commentButton: HCCommentButton = {
        let button = HCCommentButton(image: UIImage(systemName: "message")!, count: 0)
        return button
    }()

    init(posts: [Post], selectedDate: String) {
        self.posts = posts
        self.selectedDate = selectedDate
        super.init(frame: .zero)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        self.backgroundColor = .background
        
        [collectionView, closeButton, commentButton].forEach {
            self.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            collectionView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            collectionView.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: -20),
            collectionView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            collectionView.heightAnchor.constraint(equalTo: collectionView.widthAnchor),
            
            closeButton.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: 24),
            closeButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -24),
            closeButton.widthAnchor.constraint(equalToConstant: 60),
            closeButton.heightAnchor.constraint(equalToConstant: 40),
            
            commentButton.topAnchor.constraint(equalTo: collectionView.bottomAnchor),
            commentButton.trailingAnchor.constraint(equalTo: collectionView.trailingAnchor, constant: -20)
        ])
    }
}
