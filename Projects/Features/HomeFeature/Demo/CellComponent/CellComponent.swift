//
//  CellComponent.swift
//  HomeFeature
//
//  Created by 김동현 on 3/19/26.
//

import TurboListKit
import UIKit
import SwiftUI

extension CellComponent: View {}
struct CellComponent: Component {

    typealias CellUIView = CellView
    let number: Int
    
    /// FlowSizable Protocol
    func size(cellSize: CGSize) -> CGSize {
        return CGSize(
            width: cellSize.width,
            height: cellSize.width
        )
    }
    
    /// Component Protocol
    /// 최초 1번 실행
    func createCellUIView() -> CellUIView {
        return CellView()
    }
    
    /// Component Protocol
    /// 매번 실행
    func render(context: Context, content: CellUIView) {
        content.setTitle(number)
    }
}

final class CellView: UIView, Touchable, TouchAnimatable {
    
    private let titleLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension CellView {
    
    func setupUI() {
        backgroundColor = .green
        addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // corner
        layer.cornerRadius = 12
        layer.cornerCurve = .continuous
        layer.masksToBounds = true
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .black
    }
}

extension CellView {
    
    func setTitle(_ number: Int) {
        titleLabel.text = String(number)
    }
    
    func setBackground(_ color: UIColor) {
        self.backgroundColor = color
    }
}
