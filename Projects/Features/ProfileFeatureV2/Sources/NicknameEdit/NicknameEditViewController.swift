import DSKit
import RxCocoa
import RxSwift
import UIKit

final class NicknameEditViewController:
    UIViewController
{
    private let viewModel:
        NicknameEditViewModel
    private let customView =
        NicknameEditView()
    private let disposeBag =
        DisposeBag()

    init(
        viewModel:
            NicknameEditViewModel
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
        let backItem =
            UIBarButtonItem()
        backItem.title =
            LocalizationKey.commonBack
                .localized
        backItem.tintColor =
            .mainWhite
        navigationItem
            .backBarButtonItem =
            backItem
        navigationController?
            .navigationBar.tintColor =
            .mainWhite
    }

    private func bindViewModel() {
        let input =
            NicknameEditViewModel.Input(
                nicknameText:
                    customView.textField
                        .rx.text.orEmpty
                        .asObservable(),
                endButtonTapped:
                    customView.endButton
                        .rx.tap
                        .asObservable()
            )
        let output =
            viewModel.transform(
                input: input
            )

        output.isNicknameValid
            .drive(with: self) {
                owner, isValid in
                owner.customView
                    .endButton.isEnabled =
                    isValid
                owner.customView
                    .endButton.alpha =
                    isValid ? 1 : 0.5
            }
            .disposed(by: disposeBag)

        customView.textField.rx
            .controlEvent(
                .editingDidEndOnExit
            )
            .asDriver()
            .drive(with: self) {
                owner, _ in
                owner.view
                    .endEditing(true)
            }
            .disposed(by: disposeBag)
    }
}
