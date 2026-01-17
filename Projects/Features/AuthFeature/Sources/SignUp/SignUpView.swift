//
//  SignUpView.swift
//  AuthFeature
//
//  Created by 김동현 on 1/16/26.
//

import UIKit

final class SignUpView: UIView {
    // MARK: - Events
    var onBackTapped: (() -> Void)?
    var onSkipTapped: (() -> Void)?
    var onNextTapped: (() -> Void)?
    
    let backButton = UIButton()
    let skipButton = UIButton()
    
    let scrollView = UIScrollView()
    let contentView = UIView()
    
    let nicknameSettingView = NicknameSettingView()
    let birthDaySettingView = BirthdaySettingView()
    let profileSettingView = ProfileSettingView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .background
        
        scrollView.isPagingEnabled = true
        scrollView.isScrollEnabled = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        
        // 버튼 타겟 연결
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        skipButton.addTarget(self, action: #selector(skipTapped), for: .touchUpInside)
        nicknameSettingView.nextButton.addTarget(self ,action: #selector(nextTapped), for: .touchUpInside)
        birthDaySettingView.nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        
        addSubview(scrollView)
        scrollView.addSubview(contentView)
        [nicknameSettingView, birthDaySettingView, profileSettingView].forEach {
            contentView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
    }

    // MARK: - Constraints
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // MARK: - ScrollView
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
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
            nicknameSettingView.topAnchor.constraint(equalTo: contentView.topAnchor),
            nicknameSettingView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            nicknameSettingView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            nicknameSettingView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            // MARK: - Page 2 (Birthday)
            birthDaySettingView.topAnchor.constraint(equalTo: contentView.topAnchor),
            birthDaySettingView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            birthDaySettingView.leadingAnchor.constraint(equalTo: nicknameSettingView.trailingAnchor),
            birthDaySettingView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            
            // MARK: - Page 3 (Profile)
            profileSettingView.topAnchor.constraint(equalTo: contentView.topAnchor),
            profileSettingView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            profileSettingView.leadingAnchor.constraint(equalTo: birthDaySettingView.trailingAnchor),
            profileSettingView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            profileSettingView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
    }

    // MARK: - Page Control
    func move(to index: Int, animated: Bool = true) {
        let x = scrollView.frame.width * CGFloat(index)
        scrollView.setContentOffset(CGPoint(x: x, y: 0), animated: animated)
    }
    
    func moveToNicknamePage(animated: Bool = true) {
        scrollView.setContentOffset(.zero, animated: animated)
    }
    
    @objc private func backTapped() {
        onBackTapped?()
    }
    
    @objc private func skipTapped() {
        onSkipTapped?()
    }
    
    @objc private func nextTapped() {
        onNextTapped?()
    }
}

#if DEBUG
final class SignUpPreviewVC: UIViewController {
    override func loadView() {
        self.view = SignUpView()
    }
}
#endif

#Preview {
    SignUpPreviewVC()
}
