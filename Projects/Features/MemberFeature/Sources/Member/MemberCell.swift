//
//  MemberCell.swift
//  MemberFeature
//
//  Created by 김동현 on 3/4/26.
//

import UIKit
import DSKit
import Domain

final class MemberCell: UICollectionViewCell {

    private lazy var circleView: UIView = {
        let view = UIView()
        view.backgroundColor = .gray300
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = .gray
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .hcFont(.bold, size: 14)
        lbl.textColor = .mainWhite
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private lazy var hStack: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [circleView, nameLabel])
        sv.axis = .horizontal
        sv.alignment = .center
        sv.spacing = 12
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.kf.cancelDownloadTask()
        imageView.image = nil
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        contentView.addSubview(hStack)
        circleView.addSubview(imageView)
        
        circleView.layer.cornerRadius = 30
        imageView.layer.cornerRadius = 30
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            
            hStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            hStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            hStack.topAnchor.constraint(equalTo: contentView.topAnchor),
            hStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            circleView.widthAnchor.constraint(equalToConstant: 60),
            circleView.heightAnchor.constraint(equalTo: circleView.widthAnchor),
            
            imageView.leadingAnchor.constraint(equalTo: circleView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: circleView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: circleView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: circleView.bottomAnchor)
        ])
    }
    
    func configure(user: User) {
        imageView.contentMode = .scaleAspectFill
        circleView.backgroundColor = .gray300
        nameLabel.text = user.nickname
        
        if let urlString = user.profileImageURL,
           let url = URL(string: urlString) {
            imageView.kf.setImage(with: url)
            
        } else {
            imageView.image = UIImage(systemName: "person.fill")
        }
    }
    
    func configureInvite() {
        /*
        nameLabel.text = ""
        imageView.image = UIImage(systemName: "plus")
        circleView.backgroundColor = .hcColor
         */
        nameLabel.text = ""
        imageView.contentMode = .center
        imageView.image = UIImage(systemName: "plus")
        imageView.tintColor = .white
        circleView.backgroundColor = .gray
    }
}
