//
//  SimpleTextComponent.swift
//  HomeFeatureV2
//
//  Created by 김동현 on 4/19/26.
//

import Foundation
import UIKit
import CarbonListKit

struct SimpleTextComponent: ListComponent {
    let id: String = UUID().uuidString
    
    struct Content: Equatable {
        let title: String
        let subtitle: String
    }
    
    let content: Content
    
    func makeView(context: ListComponentContext<Void>) -> SimpleTextRowView {
        SimpleTextRowView()
    }
    
    func updateView(_ view: SimpleTextRowView, context: ListComponentContext<Void>) {
        view.configure(
            title: content.title,
            subtitle: content.subtitle
        )
    }
    
    var height: ListComponentHeight {
        return .square
    }
}

extension SimpleTextComponent: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.content == rhs.content
    }
}

final class SimpleTextRowView: UIView {
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        enablePressedEffect()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // backgroundColor = .tertiarySystemBackground
        backgroundColor = .tertiarySystemBackground
        layer.cornerRadius = 12
        
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.numberOfLines = 0
        
        subtitleLabel.font = .systemFont(ofSize: 13)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0
        
        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.spacing = 6
        
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
    }
    
    func configure(title: String, subtitle: String) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
    }
}
