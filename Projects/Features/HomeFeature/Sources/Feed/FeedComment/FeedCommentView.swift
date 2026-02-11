//  FeedCommentViewView.swift
//  Haruhancut
//
//  Created by 김동현 on 6/19/25.
//

import UIKit
import Domain
import DSKit

public final class FeedCommentView: UIView {
    
    let post: Post
    
    // MARK: - Dynamic
    private var dynamicConstraint: NSLayoutConstraint?
    
    // MARK: - UI Component
    private let headerLabel: UILabel = {
        let label = HCLabel(type: .commentTitle(text: "댓글"))
        return label
    }()
    
    public lazy var tableView: UITableView = {
        let tv = UITableView()
        tv.register(CommentCell.self, forCellReuseIdentifier: CommentCell.reuseIdentifier)
        tv.separatorStyle = .none /// 셀 사이의 구분선(separator) 을 제거
        tv.backgroundColor = .clear
        return tv
    }()
    
    public lazy var chattingView: ChattingView = {
        let chatView = ChattingView()
        /// chatView.sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        return chatView
    }()

    // MARK: - Initializer
    public init(post: Post) {
        self.post = post
        super.init(frame: .zero)
        setupUI()
        setupConstraints()
        
        if let constraint = dynamicConstraint {
            self.bindKeyboard(to: constraint)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Setup
    private func setupUI() {
        backgroundColor = .gray700
        [headerLabel, tableView, chattingView].forEach {
            self.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }

    // MARK: - Constraints
    private func setupConstraints() {
        
        
        // MARK: - Dynamic
        dynamicConstraint = chattingView.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor, constant: -10)
        dynamicConstraint?.isActive = true
        
        NSLayoutConstraint.activate([
            
            // MARK: - 헤더
            headerLabel.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: 20),
            headerLabel.centerXAnchor.constraint(equalTo: self.safeAreaLayoutGuide.centerXAnchor),
            
            // MARK: - 테이블뷰
            tableView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: chattingView.topAnchor),
            
            // MARK: - 채팅뷰
            chattingView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            chattingView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16),
            dynamicConstraint!
        ])
    }
}

//#Preview {
//    FeedCommentView(post: Post.samplePosts[0])
//}
