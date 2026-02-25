//
//  CalendarDetailCell.swift
//  HomeFeature
//
//  Created by 김동현 on 2/24/26.
//

import UIKit
import Kingfisher

final class CalendarDetailCell: UICollectionViewCell {
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 15
        iv.clipsToBounds = true
        iv.backgroundColor = .secondarySystemBackground
        return iv
    }()
    
    
    
    /// UIView(그리고 UICollectionViewCell, UITableViewCell 등) 생성자(Initializer) 중 하나
    /// UIKit의 거의 모든 View, Cell, Layout은 “프로그래밍으로” 만들 때 init(frame: CGRect)라는 생성자를 사용
    /// frame
    /// “이 View가 superview(상위 뷰)에서 어느 위치, 어느 크기로 들어갈지”를 의미
    /// 보통 코드로 View를 만들 때 직접 frame을 넘겨주거나, 오토레이아웃을 쓰면 frame: .zero로 두고, 제약조건(Constraints)으로 나중에 크기/위치를 결정
    /// 커스텀 셀을 만들 때 반드시 required init?(coder:)와 override init(frame: CGRect) 이 두 개를 구현해야 함
    /// override init(frame: CGRect)는 "코드로 뷰(혹은 셀)를 만들 때, 초기화(셋업) 하는 생성자"다!
    ///  frame: .zero로 넣고 오토레이아웃 쓰는 건 “처음엔 크기 0, 실제 사이즈는 나중에 constraints로 결정”이라는 의미
    override init(frame: CGRect) {
        super.init(frame: frame)
        makeUI()
        constraints()
        // imageCallback()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.kf.cancelDownloadTask()
        imageView.image = nil
    }
    
    private func makeUI() {
        contentView.backgroundColor = .clear
        contentView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func constraints() {
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }
    
    func setKFImage(url: String) {
        if let url = URL(string: url) {
            imageView.kf.setImage(with: url)
        }
    }
    
}
