//
//  HeaderComponent.swift
//  HomeFeature
//
//  Created by 김동현 on 3/19/26.
//

import TurboListKit
import UIKit
import SwiftUI

extension Header: View {}
struct Header: HeaderComponent {
    
    typealias CellUIView = HeaderView
    let title: String
    
    func size(cellSize: CGSize) -> CGSize {
        return CGSize(
            width: cellSize.width,
            height: 40
        )
    }
    
    func createCellUIView() -> HeaderView {
        return HeaderView()
    }

    func render(context: Context, content: CellUIView) {
        content.setTitle(title)
        content.setBackground(.clear)
    }
}

final class HeaderView: UIView, Touchable {
    
    private let titleLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        backgroundColor = .systemBackground
        addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .mainWhite
    }
}

extension HeaderView {
    
    func setTitle(_ title: String) {
        titleLabel.text = title
    }
    
    func setBackground(_ color: UIColor) {
        self.backgroundColor = color
    }
}
