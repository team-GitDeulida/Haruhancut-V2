//
//  Empty.swift
//  Profile
//
//  Created by 김동현 on 
//

import UIKit
import DSKit
import Kingfisher

public final class ProfileView: UIView {
    
    // MARK: - UI Component
    public lazy var profileImageView: ProfileImageView = {
        let imageView = ProfileImageView(size: 100, iconSize: 60)
        return imageView
    }()
    
    public lazy var nicknameLabel: HCLabel = {
        let label = HCLabel(type: .main(text: ""))
        return label
    }()
    
    public lazy var editButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "pencil"), for: .normal)
        button.tintColor = .mainWhite
        return button
    }()
    
    private lazy var hStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [profileImageView,
                                                   UIView(),
                                                   nicknameLabel,
                                                   UIView(),
                                                   editButton])
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center
        return stack
    }()
    
    public lazy var collectionView: UICollectionView = {
        let spacing: CGFloat = 1 // 셀 사이 간격
        let columns: CGFloat = 3 // 한 줄에 3개
        
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = spacing // 같은 줄에서 아이템 사이 가로 간격
        layout.minimumLineSpacing = spacing      // 줄과 줄 사이 세로 간격
        layout.sectionInset = .zero              // 전체 섹션의 여백
        
        // .zero: 오토레이아웃
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.register(ProfilePostCell.self, forCellWithReuseIdentifier: ProfilePostCell.reuseIdentifier)
        cv.backgroundColor = .clear
        return cv
    }()
    
    public init() {
        super.init(frame: .zero)
        setupUI()
        setupConstraints()
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        backgroundColor = .background
        [hStack, collectionView].forEach {
            self.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }

    // MARK: - Constraints
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: 30),
            hStack.centerXAnchor.constraint(equalTo: self.safeAreaLayoutGuide.centerXAnchor),
            hStack.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            
            collectionView.topAnchor.constraint(equalTo: hStack.bottomAnchor, constant: 50),
            collectionView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }
}
