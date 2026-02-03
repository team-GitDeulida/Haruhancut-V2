//  GroupViewView.swift
//  AuthFeature
//
//  Created by 김동현 on 2/3/26.
//

import UIKit

final class GroupView: UIView {
    
    // MARK: - UI Component
    let scrollView: UIScrollView={
        let view = UIScrollView()
        view.isPagingEnabled = true
        view.isScrollEnabled = false
        view.contentInsetAdjustmentBehavior = .never
        return view
    }()
    let contentView = UIView()
    
    // MARK: - View
    let groupSelectView = GroupSelectView()
    let groupHostView = GroupHostView()
    let groupEnterView = GroupEnterView()

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
        
        addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        [groupSelectView, groupHostView, groupEnterView].forEach {
            contentView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }

    // MARK: - Constraints
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // MARK: - ScrollView
            scrollView.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            // MARK: - ContentView
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            
            // 세로는 고정, 가로만 늘림
            contentView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, multiplier: 3),
            
            // MARK: - Page 1 (Nickname)
            groupSelectView.topAnchor.constraint(equalTo: contentView.topAnchor),
            groupSelectView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            groupSelectView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            groupSelectView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            
            // MARK: - Page 2
            groupHostView.topAnchor.constraint(equalTo: contentView.topAnchor),
            groupHostView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            groupHostView.leadingAnchor.constraint(equalTo: groupSelectView.trailingAnchor),
            groupHostView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            
            // MARK: - Page 3
            groupEnterView.topAnchor.constraint(equalTo: contentView.topAnchor),
            groupEnterView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            groupEnterView.leadingAnchor.constraint(equalTo: groupHostView.trailingAnchor),
            groupEnterView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
        ])
    }
    
    // MARK: - Page Control
    func move(to index: Int, animated: Bool = true) {
        let x = scrollView.frame.width * CGFloat(index)
        scrollView.setContentOffset(CGPoint(x: x, y: 0), animated: animated)
    }
}

#Preview {
    GroupView()
}
