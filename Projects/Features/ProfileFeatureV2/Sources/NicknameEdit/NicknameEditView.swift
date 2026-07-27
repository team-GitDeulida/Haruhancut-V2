import DSKit
import UIKit

final class NicknameEditView: UIView {
    private let titleLabel: UILabel = {
        HCLabel(
            type: .main(
                text:
                    LocalizationKey
                        .profileNicknameEditTitle
                        .localized
            )
        )
    }()

    private let subtitleLabel:
        UILabel = {
            HCLabel(
                type: .sub(
                    text:
                        LocalizationKey
                            .profileNicknameEditSubtitle
                            .localized
                )
            )
        }()

    let textField: UITextField = {
        HCTextField(
            placeholder:
                LocalizationKey
                    .profileNicknameEditPlaceholder
                    .localized
        )
    }()

    let endButton: UIButton = {
        HCNextButton(
            title:
                LocalizationKey
                    .profileNicknameEditComplete
                    .localized
        )
    }()

    private lazy var labelStackView:
        UIStackView = {
            let stackView = UIStackView(
                arrangedSubviews: [
                    titleLabel,
                    subtitleLabel,
                ]
            )
            stackView.spacing = 10
            stackView.axis = .vertical
            stackView.alignment = .fill
            return stackView
        }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
        configureLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError(
            "init(coder:)는 지원하지 않습니다."
        )
    }

    override func touchesBegan(
        _ touches: Set<UITouch>,
        with event: UIEvent?
    ) {
        super.touchesBegan(
            touches,
            with: event
        )
        endEditing(true)
    }

    private func configureView() {
        backgroundColor = .background

        [
            labelStackView,
            textField,
            endButton,
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints =
                false
            addSubview($0)
        }
    }

    private func configureLayout() {
        NSLayoutConstraint.activate([
            labelStackView.topAnchor
                .constraint(
                    equalTo:
                        safeAreaLayoutGuide
                            .topAnchor,
                    constant: 30
                ),
            labelStackView.leadingAnchor
                .constraint(
                    equalTo:
                        safeAreaLayoutGuide
                            .leadingAnchor,
                    constant: 20
                ),
            labelStackView.trailingAnchor
                .constraint(
                    lessThanOrEqualTo:
                        safeAreaLayoutGuide
                            .trailingAnchor,
                    constant: -20
                ),
            textField.topAnchor
                .constraint(
                    equalTo:
                        labelStackView
                            .bottomAnchor,
                    constant: 30
                ),
            textField.leadingAnchor
                .constraint(
                    equalTo:
                        safeAreaLayoutGuide
                            .leadingAnchor,
                    constant: 20
                ),
            textField.trailingAnchor
                .constraint(
                    equalTo:
                        safeAreaLayoutGuide
                            .trailingAnchor,
                    constant: -20
                ),
            textField.heightAnchor
                .constraint(
                    equalToConstant: 50
                ),
            endButton.leadingAnchor
                .constraint(
                    equalTo:
                        safeAreaLayoutGuide
                            .leadingAnchor,
                    constant: 20
                ),
            endButton.trailingAnchor
                .constraint(
                    equalTo:
                        safeAreaLayoutGuide
                            .trailingAnchor,
                    constant: -20
                ),
            endButton.heightAnchor
                .constraint(
                    equalToConstant: 50
                ),
            endButton.bottomAnchor
                .constraint(
                    equalTo:
                        keyboardLayoutGuide
                            .topAnchor,
                    constant: -10
                ),
        ])
    }
}
