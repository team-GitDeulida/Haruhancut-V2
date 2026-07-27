import DSKit
import UIKit

final class BirthdayEditView: UIView {
    private let titleLabel: UILabel = {
        HCLabel(
            type: .main(
                text:
                    LocalizationKey
                        .profileBirthdayEditTitle
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
                            .profileBirthdayEditSubtitle
                            .localized
                )
            )
        }()

    let datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle =
            .wheels
        picker.locale =
            .autoupdatingCurrent
        picker.timeZone =
            .autoupdatingCurrent
        picker.maximumDate = .now
        return picker
    }()

    let endButton: UIButton = {
        HCNextButton(
            title:
                LocalizationKey
                    .profileBirthdayEditComplete
                    .localized
        )
    }()

    private lazy var labelStackView:
        UIStackView = {
            let stackView =
                UIStackView(
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

    private func configureView() {
        backgroundColor = .background

        [
            labelStackView,
            datePicker,
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
                    equalTo:
                        safeAreaLayoutGuide
                            .trailingAnchor,
                    constant: -20
                ),

            datePicker.topAnchor
                .constraint(
                    equalTo:
                        labelStackView
                            .bottomAnchor,
                    constant: 24
                ),
            datePicker.leadingAnchor
                .constraint(
                    equalTo:
                        safeAreaLayoutGuide
                            .leadingAnchor,
                    constant: 20
                ),
            datePicker.trailingAnchor
                .constraint(
                    equalTo:
                        safeAreaLayoutGuide
                            .trailingAnchor,
                    constant: -20
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
                        safeAreaLayoutGuide
                            .bottomAnchor,
                    constant: -10
                ),
        ])
    }
}
