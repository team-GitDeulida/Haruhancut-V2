//
//  SettingViewController.swift
//  ProfileFeature
//
//  Created by 김동현 on 3/2/26.
//

import UIKit
import RxSwift
import RxRelay
import SafariServices
import RxCocoa
import RxDataSources
import Core
import DSKit

final class SettingViewController: UIViewController {
    private let settingViewModel: SettingViewModel
    private let customView = SettingView()
    private let disposeBag = DisposeBag()
    
    // MARK: - Event
    private let notificationToggleSubject = PublishSubject<Bool>()
    private let cellSelectedSubject     = PublishSubject<IndexPath>()
    
    // MARK: - Initializer
    init(settingViewModel: SettingViewModel
    ) {
        self.settingViewModel = settingViewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - LifeCycle
    override func loadView() {
        self.view = customView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func bind() {
        let toggleTapped = PublishRelay<Bool>()
        let withdrawalTapped = PublishRelay<Void>()
        
        let input = SettingViewModel.Input(
            logoutTapped: customView.logoutButton.rx.tap.asObservable(),
            notificationToggleTapped: toggleTapped.asObservable(),
            withdrawalTapped: withdrawalTapped.asObservable())
        let output = settingViewModel.transform(input: input)
        
        let dataSource = RxTableViewSectionedReloadDataSource<SettingSection>(
            configureCell: { [weak self] dataSource, tableView, indexPath, item in
                guard let _ = self else { return UITableViewCell() }
                
                guard let cell = tableView.dequeueReusableCell(withIdentifier: SettingCell.reuseIdentifier,
                                                               for: indexPath
                ) as? SettingCell else {
                    return UITableViewCell()
                }
                cell.selectionStyle = .none
                cell.bindeCell(option: item)
                
                // toggle 상태 세팅
                if case .toggle = item {
                    cell.toggleSwitch.rx
                        .isOn
                        .skip(1)
                        .bind(to: toggleTapped)
                        .disposed(by: cell.disposeBag)
                    
                    output.notificationState
                        .drive(cell.toggleSwitch.rx.isOn)
                        .disposed(by: cell.disposeBag)
                    
                }
                return cell
        })
        
        // 헤더
        dataSource.titleForHeaderInSection = { dataSource, index in
            dataSource.sectionModels[index].header
        }
        
        // Section 바인딩
        Observable.just(customView.sections)
            .bind(to: customView.tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        // 알림기능
        output.showPermissionALert
            .emit(with: self, onNext: { owner, _ in
                owner.showNotificationPermissionAlert()
            })
            .disposed(by: disposeBag)
        
        // 웹뷰 이동 + 회원탈퇴
        customView.tableView.rx.modelSelected(SettingOption.self)
            .bind(with: self, onNext: { owner, option in
                switch option {
                // 개인정보 처리방침
                case .privacyPolicy:
                    guard let url = URL(string: Constants.Notion.privatePolicy) else { return }
                    let safariVC = SFSafariViewController(url: url)
                    owner.present(safariVC, animated: true)
                // 공지사항
                case .announce:
                    guard let url = URL(string: Constants.Notion.announce) else { return }
                    let safariVC = SFSafariViewController(url: url)
                    owner.present(safariVC, animated: true)
                    
                // 회원탈퇴 알림창
                case .withdraw:
                    let alert = AlertFactory.makeAlert(title: "profile.setting.withdraw.alert.title".localized(),
                                           message: "profile.setting.withdraw.alert.message".localized(),
                                           actions: [
                                            UIAlertAction(title: "profile.setting.withdraw.alert.confirm".localized(), style: .destructive) { _ in
                                                // 삭제 이벤트를 viewModel로 보내겠다
                                                withdrawalTapped.accept(())
                                            },
                                            UIAlertAction(title: "common.cancel".localized(), style: .cancel)
                                           ])
                    owner.present(alert, animated: true)
                default:
                    break
                }
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - Alert
extension SettingViewController {
    // MARK: - 사용자에게 설정으로 유도하는 알림창
    func showNotificationPermissionAlert() {
        let alert = UIAlertController(
            title: "profile.setting.notification.alert.title".localized(),
            message: "profile.setting.notification.alert.message".localized(),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "profile.setting.notification.alert.open_settings".localized(), style: .default, handler: { _ in
            self.openAppSettings()
        }))
        alert.addAction(UIAlertAction(title: "common.cancel".localized(), style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - 설정 앱으로 이동 함수
    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}

