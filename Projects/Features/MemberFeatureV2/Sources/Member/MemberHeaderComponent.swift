import CollectionViewAdapter
import DSKit
import UIKit

struct MemberHeaderComponent: Component {
    typealias Item =
        MemberHeaderContentView.Item

    let item: Item

    init(
        memberCount: Int,
        showsBirthdaySettingsButton:
            Bool = false
    ) {
        item = Item(
            id: "member-count-header",
            memberCount: memberCount,
            showsBirthdaySettingsButton:
                showsBirthdaySettingsButton
        )
    }

    var estimatedHeight: CGFloat {
        70
    }

    func createContent()
        -> MemberHeaderContentView
    {
        MemberHeaderContentView()
    }

    func render(
        context _: ComponentContext,
        content: MemberHeaderContentView
    ) {
        content.item = item
    }
}

final class MemberHeaderContentView:
    UIView,
    ContainsButton
{
    struct Item:
        Identifiable,
        Equatable
    {
        let id: String
        let memberCount: Int
        let showsBirthdaySettingsButton:
            Bool
    }

    private enum Layout {
        static let topInset:
            CGFloat = 24
        static let bottomInset:
            CGFloat = 20
        static let spacing:
            CGFloat = 5
    }

    var item: Item? {
        didSet {
            guard item != oldValue else {
                return
            }
            applyItem()
        }
    }

    let buttonTapEvent =
        ComponentEvent<Void>()

    private let titleLabel: UILabel = {
        let label = HCLabel(
            type: .main(
                text:
                    LocalizationKey
                        .memberFamilyCount
                        .localized
            )
        )
        label.font =
            .hcFont(
                .bold,
                size: 22.scaled
            )
        label.accessibilityTraits =
            .header
        return label
    }()

    private let countLabel: UILabel = {
        let label = HCLabel(
            type: .main(text: "")
        )
        label.font =
            .hcFont(
                .bold,
                size: 22.scaled
            )
        label.textColor = .hcColor
        return label
    }()

    private lazy var titleStack:
        UIStackView = {
            let stackView =
                UIStackView(
                    arrangedSubviews: [
                        titleLabel,
                        countLabel,
                    ]
                )
            stackView.axis = .horizontal
            stackView.spacing =
                Layout.spacing
            stackView.alignment = .center
            return stackView
        }()

    private let settingsButton:
        UIButton = {
            let button =
                UIButton(
                    type: .system
                )
            button.setImage(
                UIImage(
                    systemName:
                        "ellipsis.circle"
                ),
                for: .normal
            )
            button.tintColor =
                .mainWhite
            button.accessibilityLabel =
                LocalizationKey
                    .memberBirthdaySettingsButton
                    .localized
            button.isHidden = true
            return button
        }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
        configureLayout()
        settingsButton.addTarget(
            self,
            action:
                #selector(
                    didTapSettings
                ),
            for: .touchUpInside
        )
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
            titleStack,
            settingsButton,
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints =
                false
            addSubview($0)
        }
    }

    private func configureLayout() {
        NSLayoutConstraint.activate([
            titleStack.topAnchor
                .constraint(
                    equalTo: topAnchor,
                    constant:
                        Layout.topInset
                ),
            titleStack.leadingAnchor
                .constraint(
                    equalTo: leadingAnchor
                ),
            titleStack.trailingAnchor
                .constraint(
                    lessThanOrEqualTo:
                        settingsButton
                            .leadingAnchor,
                    constant: -12
                ),
            titleStack.bottomAnchor
                .constraint(
                    equalTo: bottomAnchor,
                    constant:
                        -Layout.bottomInset
                ),
            settingsButton.trailingAnchor
                .constraint(
                    equalTo:
                        trailingAnchor
                ),
            settingsButton.centerYAnchor
                .constraint(
                    equalTo:
                        titleStack
                            .centerYAnchor
                ),
            settingsButton.widthAnchor
                .constraint(
                    equalToConstant: 36
                ),
            settingsButton.heightAnchor
                .constraint(
                    equalTo:
                        settingsButton
                            .widthAnchor
                ),
        ])
    }

    private func applyItem() {
        guard let item else {
            countLabel.text = nil
            settingsButton.isHidden = true
            return
        }

        countLabel.text = String(
            format:
                LocalizationKey
                    .memberFamilyCountValue
                    .localized,
            item.memberCount
        )
        settingsButton.isHidden =
            !item
                .showsBirthdaySettingsButton
    }

    @objc
    private func didTapSettings() {
        buttonTapEvent.send(())
    }
}
