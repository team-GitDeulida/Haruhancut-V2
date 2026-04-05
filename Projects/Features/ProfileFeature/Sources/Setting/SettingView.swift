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
        SettingSection(header: "profile.setting.section.app".localized(), items: [
            .toggle(title: "profile.setting.notification".localized())
        ]),
        SettingSection(header: "profile.setting.section.info".localized(), items: [
            .version(title: "profile.setting.version".localized(), detail: "\(appVersion)"),
            .privacyPolicy(title: "profile.setting.privacy".localized()),
            .announce(title: "profile.setting.announce".localized())
        ]),
        SettingSection(header: "profile.setting.section.account".localized(), items: [
            .withdraw(title: "profile.setting.withdraw".localized())
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
        let button = HCNextButton(title: "profile.setting.logout".localized())
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
