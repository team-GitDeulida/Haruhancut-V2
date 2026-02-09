//  FeedViewView.swift
//  Haruhancut
//
//  Created by 김동현 on 6/18/25.
//

import UIKit
import DSKit

final class FeedView: UIView {
    
    // MARK: - UI Component
    let refreshControl = UIRefreshControl()
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        // layout.itemSize = layout.calculateItemSize(columns: 2)
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        layout.minimumInteritemSpacing = 16      // 좌우 셀 간격
        layout.minimumLineSpacing = 16           // 위아래 셀 간격
        
        let collectionView = UICollectionView(frame: .zero,
                                              collectionViewLayout: layout)
        collectionView.register(FeedCell.self,
                                forCellWithReuseIdentifier: FeedCell.reuseIdentifier)
        collectionView.backgroundColor = .background
        collectionView.refreshControl = refreshControl
        collectionView.showsVerticalScrollIndicator = false
        return collectionView
    }()
    
    let bubbleView = BubbleView(text: "사진 추가하기")
    
    lazy var cameraBtn: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "button.programmable"), for: .normal)
        button.tintColor = .mainWhite
        button.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 70.scaled), forImageIn: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        return button
    }()
    
    lazy var emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "당신의 하루가 가족의 따뜻한 기억이 됩니다.\n사진 한 장을 남겨주세요."
        label.font = UIFont.hcFont(.medium, size: 20.scaled)
        label.textColor = .mainWhite
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    // MARK: - Initializer
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
        backgroundColor = .background
        [collectionView, cameraBtn, bubbleView, emptyLabel].forEach {
            self.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }

    // MARK: - Constraints
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // 컬렉션뷰
            collectionView.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: 20),
            collectionView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: cameraBtn.topAnchor, constant: -20),

            // 카메라 버튼
            cameraBtn.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -50),
            cameraBtn.centerXAnchor.constraint(equalTo: self.centerXAnchor),

            // 말풍선
            bubbleView.bottomAnchor.constraint(equalTo: cameraBtn.topAnchor, constant: -10),
            bubbleView.centerXAnchor.constraint(equalTo: self.centerXAnchor),

            // emptyLabel (가운데 정렬)
            emptyLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: -50.scaled)
        ])
    }
}

#Preview {
    FeedView()
}
