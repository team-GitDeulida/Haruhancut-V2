//
//  NumberCOmponent.swift
//  TurboListKit-Demo
//
//  Created by 김동현 on 3/6/26.
//

import TurboListKit
import UIKit
import SwiftUI

extension NumberComponent: View {}
struct NumberComponent: Component {

    typealias CellUIView = NumberView
    let number: Int
    
    /// FlowSizable Protocol
    func size(cellSize: CGSize) -> CGSize {
        return CGSize(
            width: cellSize.width,
            height: 44
        )
    }
    
    /// Component Protocol
    /// 최초 1번 실행
    func createCellUIView() -> CellUIView {
        return NumberView()
    }
    
    /// Component Protocol
    /// 매번 실행
    func render(context: Context, content: CellUIView) {
        content.setTitle(number)
        content.setBackground(.green)
    }
}

final class NumberView: UIView, Touchable, TouchAnimatable {
    
    private let titleLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

private extension NumberView {
    
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
        titleLabel.textColor = .label
    }
}

extension NumberView {
    
    func setTitle(_ number: Int) {
        titleLabel.text = String(number)
    }
    
    func setBackground(_ color: UIColor) {
        self.backgroundColor = color
    }
}
