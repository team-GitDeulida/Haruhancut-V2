//
//  CommentView.swift
//  HomeFeatureV2
//
//  Created by 김동현 on 4/22/26.
//

import UIKit
import Domain
import DSKit
import Core

final class CommentView: UIView {
    
    let post: Post
    
    // MARK: - Dynamic
    private var dynamicConstraint: NSLayoutConstraint?
    
    // MARK: - UI Component
    private let headerLabel: UILabel = {
        let label = HCLabel(type: .commentTitle(text: LocalizationKey.commentTitle.localized))
        return label
    }()
    
    public lazy var tableView: UITableView = {
        let tv = UITableView()
        tv.register(CommentCell.self, forCellReuseIdentifier: CommentCell.reuseIdentifier)
        tv.separatorStyle = .none
        tv.backgroundColor = .clear
        tv.uiTestID(UITestID.Comment.tableView)
        return tv
    }()
    
    public lazy var chattingView: ChattingView = {
        let chatView = ChattingView()
        return chatView
    }()

    public init(post: Post) {
        self.post = post
        super.init(frame: .zero)
        setupUI()
        setupConstraints()
        
        if let constraint = dynamicConstraint {
            self.bindKeyboard(to: constraint)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .gray700
        [headerLabel, tableView, chattingView].forEach {
            self.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }

    private func setupConstraints() {
        dynamicConstraint = chattingView.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor, constant: -10)
        dynamicConstraint?.isActive = true
        
        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: 20),
            headerLabel.centerXAnchor.constraint(equalTo: self.safeAreaLayoutGuide.centerXAnchor),
            
            tableView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: chattingView.topAnchor),
            
            chattingView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            chattingView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16),
            dynamicConstraint!
        ])
    }
}
