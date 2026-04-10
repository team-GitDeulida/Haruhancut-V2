//
//  MemberView.swift
//  MemberFeature
//
//  Created by 김동현 on 3/4/26.
//

import UIKit
import DSKit

final class MemberView: UIView {
    
    // MARK: - UI Component
    let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 16
        layout.scrollDirection = .vertical
        
        // .zero: 오토레이아웃
        let collectionView = UICollectionView(frame: .zero,
                                              collectionViewLayout: layout)
        collectionView.register(MemberCell.self,
                                forCellWithReuseIdentifier: MemberCell.reuseIdentifier)
        collectionView.backgroundColor = .clear
        return collectionView
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "그룹"
        label.font = UIFont.hcFont(.bold, size: 20.scaled)
        label.textColor = .mainWhite
        return label
    }()
    
    private let textLabel: UILabel = {
        let label = HCLabel(type: .main(text: LocalizationKey.memberFamilyCount.localized))
        label.font = .hcFont(.bold, size: 22.scaled)
        return label
    }()
    
    lazy var peopleLabel: UILabel = {
        let label = HCLabel(type: .main(text: String(format: LocalizationKey.memberFamilyCountValue.localized, 0)))
        label.font = .hcFont(.bold, size: 22.scaled)
        label.textColor = .hcColor
        return label
    }()
    
    private lazy var titleStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [ textLabel, peopleLabel ])
        stack.axis = .horizontal
        stack.spacing = 5
        stack.alignment = .center
        return stack
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
        self.backgroundColor = .background
        [titleStack, collectionView].forEach {
            self.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }

    // MARK: - Constraints
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // titleStack
            titleStack.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: 40),
            titleStack.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            
            // collectionView
            collectionView.topAnchor.constraint(equalTo: titleStack.bottomAnchor, constant: 20),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            collectionView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor)
        ])
    }
}
