//
//  SettingView.swift
//  ProfileFeature
//
//  Created by 김동현 on 3/2/26.
//

import UIKit
import DSKit

final class SettingView: UIView {
    
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    
    // 섹션별 데이터
    lazy var sections = [
        SettingSection(header: "앱 설정", items: [
            .toggle(title: "알림 설정")
        ]),
        SettingSection(header: "정보", items: [
            .version(title: "버전 정보", detail: "\(appVersion)"),
            .privacyPolicy(title: "개인정보처리방침"),
            .announce(title: "공지사항")
        ]),
        SettingSection(header: "계정 관리", items: [
            .withdraw(title: "회원 탈퇴")
        ])
    ]
    
    // MARK: - UI Component
    lazy var tableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = .background
        tv.register(SettingCell.self, forCellReuseIdentifier: SettingCell.reuseIdentifier)
        tv.rowHeight = 40
        tv.separatorStyle = .none
        return tv
    }()
    
    let logoutButton: UIButton = {
        let button = HCNextButton(title: "로그아웃")
        return button
    }()


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
        self.backgroundColor = .background
        
        [tableView, logoutButton].forEach {
            self.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

    }

    // MARK: - Constraints
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: self.logoutButton.topAnchor, constant: -12),
            
            logoutButton.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            logoutButton.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10),
            logoutButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10),
            logoutButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
}
