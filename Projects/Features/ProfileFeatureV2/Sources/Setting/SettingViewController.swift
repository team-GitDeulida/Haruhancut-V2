import CollectionViewAdapter
import Core
import DSKit
import RxCocoa
import RxRelay
import RxSwift
import SafariServices
import UIKit

final class SettingViewController:
    UIViewController
{
    private let viewModel:
        SettingViewModel
    private let customView =
        SettingView()
    private let disposeBag =
        DisposeBag()
    private let notificationToggleRelay =
        PublishRelay<Bool>()
    private let withdrawalRelay =
        PublishRelay<Void>()
    private var isNotificationEnabled =
        false

    private lazy var adapter =
        CollectionViewAdapter(
            collectionView:
                customView.collectionView,
            interSectionSpacing: 8
        )

    init(viewModel: SettingViewModel) {
        self.viewModel = viewModel
        super.init(
            nibName: nil,
            bundle: nil
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError(
            "init(coder:)는 지원하지 않습니다."
        )
    }

    override func loadView() {
        view = customView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?
            .navigationBar.tintColor =
            .mainWhite
        bind()
    }

    private func bind() {
        let input =
            SettingViewModel.Input(
                logoutTapped:
                    customView
                        .logoutButton
                        .rx.tap
                        .asObservable(),
                notificationToggleTapped:
                    notificationToggleRelay
                        .asObservable(),
                withdrawalTapped:
                    withdrawalRelay
                        .asObservable()
            )
        let output =
            viewModel.transform(
                input: input
            )

        output.notificationState
            .distinctUntilChanged()
            .drive(with: self) {
                owner, isEnabled in
                owner
                    .isNotificationEnabled =
                    isEnabled
                owner.render()
            }
            .disposed(by: disposeBag)

        output.showPermissionAlert
            .emit(with: self) {
                owner, _ in
                owner
                    .showNotificationPermissionAlert()
            }
            .disposed(by: disposeBag)
    }

    private func render() {
        let sections =
            makeSettingSections()

        adapter.bind(
            SectionModels {
                for section in sections {
                    LazySection(
                        identifier:
                            section.id
                    ) {
                        For(
                            of: section.items
                        ) { item in
                            SettingRowComponent(
                                item: item
                            )
                            .onTouch {
                                [weak self] in
                                self?
                                    .handleSelection(
                                        item.id
                                    )
                            }
                            .onToggle {
                                [weak self] isOn in
                                self?
                                    .notificationToggleRelay
                                    .accept(isOn)
                            }
                        }
                    }
                    .withHeader(
                        SettingSectionHeaderComponent(
                            item: .init(
                                id:
                                    "\(section.id)-header",
                                title:
                                    section.title
                            )
                        )
                    )
                    .withSectionLayout(
                        .verticalList(
                            estimatedRowHeight:
                                52
                        )
                    )
                }
            },
            animatingDifferences: false
        )
    }

    private func makeSettingSections()
        -> [SettingSectionModel]
    {
        let appVersion =
            Bundle.main.infoDictionary?[
                "CFBundleShortVersionString"
            ] as? String
            ?? "Unknown"

        return [
            SettingSectionModel(
                id: "app",
                title:
                    LocalizationKey
                        .profileSettingSectionApp
                        .localized,
                items: [
                    .init(
                        id: .notification,
                        title:
                            LocalizationKey
                                .profileSettingNotification
                                .localized,
                        accessory: .toggle(
                            isNotificationEnabled
                        ),
                        role: .normal
                    ),
                ]
            ),
            SettingSectionModel(
                id: "information",
                title:
                    LocalizationKey
                        .profileSettingSectionInfo
                        .localized,
                items: [
                    .init(
                        id: .version,
                        title:
                            LocalizationKey
                                .profileSettingVersion
                                .localized,
                        accessory:
                            .detail(appVersion),
                        role: .normal
                    ),
                    .init(
                        id: .privacyPolicy,
                        title:
                            LocalizationKey
                                .profileSettingPrivacy
                                .localized,
                        accessory: .none,
                        role: .normal
                    ),
                    .init(
                        id: .announce,
                        title:
                            LocalizationKey
                                .profileSettingAnnounce
                                .localized,
                        accessory: .none,
                        role: .normal
                    ),
                ]
            ),
            SettingSectionModel(
                id: "account",
                title:
                    LocalizationKey
                        .profileSettingSectionAccount
                        .localized,
                items: [
                    .init(
                        id: .withdraw,
                        title:
                            LocalizationKey
                                .profileSettingWithdraw
                                .localized,
                        accessory: .none,
                        role: .destructive
                    ),
                ]
            ),
        ]
    }

    private func handleSelection(
        _ id: SettingRowID
    ) {
        switch id {
        case .privacyPolicy:
            presentSafari(
                urlString:
                    Constants.Notion
                        .privatePolicy
            )

        case .announce:
            presentSafari(
                urlString:
                    Constants.Notion
                        .announce
            )

        case .withdraw:
            presentWithdrawalAlert()

        case .notification,
             .version:
            break
        }
    }

    private func presentSafari(
        urlString: String
    ) {
        guard
            let url = URL(
                string: urlString
            )
        else {
            return
        }
        present(
            SFSafariViewController(
                url: url
            ),
            animated: true
        )
    }

    private func presentWithdrawalAlert() {
        let alert =
            AlertFactory.makeAlert(
                title:
                    LocalizationKey
                        .profileSettingWithdrawAlertTitle
                        .localized,
                message:
                    LocalizationKey
                        .profileSettingWithdrawAlertMessage
                        .localized,
                actions: [
                    UIAlertAction(
                        title:
                            LocalizationKey
                                .profileSettingWithdrawAlertConfirm
                                .localized,
                        style: .destructive
                    ) {
                        [weak self] _ in
                        self?
                            .withdrawalRelay
                            .accept(())
                    },
                    UIAlertAction(
                        title:
                            LocalizationKey
                                .commonCancel
                                .localized,
                        style: .cancel
                    ),
                ]
            )
        present(
            alert,
            animated: true
        )
    }

    private func showNotificationPermissionAlert() {
        let alert = UIAlertController(
            title:
                LocalizationKey
                    .profileSettingNotificationAlertTitle
                    .localized,
            message:
                LocalizationKey
                    .profileSettingNotificationAlertMessage
                    .localized,
            preferredStyle: .alert
        )
        alert.addAction(
            UIAlertAction(
                title:
                    LocalizationKey
                        .profileSettingNotificationAlertOpenSettings
                        .localized,
                style: .default
            ) {
                [weak self] _ in
                self?.openAppSettings()
            }
        )
        alert.addAction(
            UIAlertAction(
                title:
                    LocalizationKey
                        .commonCancel
                        .localized,
                style: .cancel
            )
        )
        present(
            alert,
            animated: true
        )
    }

    private func openAppSettings() {
        guard
            let url = URL(
                string:
                    UIApplication
                        .openSettingsURLString
            ),
            UIApplication.shared
                .canOpenURL(url)
        else {
            return
        }
        UIApplication.shared.open(url)
    }
}
