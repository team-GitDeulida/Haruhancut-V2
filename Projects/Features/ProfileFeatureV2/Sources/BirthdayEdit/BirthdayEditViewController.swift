import DSKit
import RxSwift
import UIKit

final class BirthdayEditViewController:
    UIViewController
{
    private let viewModel:
        BirthdayEditViewModel
    private let customView =
        BirthdayEditView()
    private let disposeBag =
        DisposeBag()

    init(
        viewModel:
            BirthdayEditViewModel
    ) {
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
        configureNavigation()
        bindViewModel()
    }

    private func configureNavigation() {
        navigationController?
            .navigationBar.tintColor =
            .mainWhite
    }

    private func bindViewModel() {
        let input =
            BirthdayEditViewModel.Input(
                birthdayDate:
                    customView
                        .datePicker
                        .rx.date
                        .asObservable(),
                endButtonTapped:
                    customView
                        .endButton
                        .rx.tap
                        .asObservable()
            )
        let output =
            viewModel.transform(
                input: input
            )

        output.initialBirthdayDate
            .drive(
                customView
                    .datePicker
                    .rx.date
            )
            .disposed(by: disposeBag)

        output.isSaving
            .drive(with: self) {
                owner, isSaving in
                owner.customView
                    .endButton
                    .isEnabled =
                    !isSaving
                owner.customView
                    .endButton
                    .alpha =
                    isSaving
                    ? 0.5
                    : 1
            }
            .disposed(by: disposeBag)

        output.saveFailed
            .emit(with: self) {
                owner, _ in
                owner.showSaveFailure()
            }
            .disposed(by: disposeBag)
    }

    private func showSaveFailure() {
        let alert =
            UIAlertController(
                title:
                    LocalizationKey
                        .profileBirthdayEditFailureTitle
                        .localized,
                message:
                    LocalizationKey
                        .profileBirthdayEditFailureMessage
                        .localized,
                preferredStyle:
                    .alert
            )
        alert.addAction(
            UIAlertAction(
                title:
                    LocalizationKey
                        .commonClose
                        .localized,
                style: .default
            )
        )
        present(
            alert,
            animated: true
        )
    }
}
