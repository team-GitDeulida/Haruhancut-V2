import CollectionViewAdapter
import DSKit
import UIKit

enum SettingRowID:
    String,
    Hashable
{
    case notification
    case version
    case privacyPolicy
    case announce
    case withdraw
}

struct SettingSectionModel:
    Identifiable,
    Equatable
{
    let id: String
    let title: String
    let items:
        [SettingRowContentView.Item]
}

struct SettingRowComponent: Component {
    typealias Item =
        SettingRowContentView.Item

    let item: Item

    var estimatedHeight: CGFloat {
        52
    }

    func createContent()
        -> SettingRowContentView
    {
        SettingRowContentView()
    }

    func render(
        context _: ComponentContext,
        content: SettingRowContentView
    ) {
        content.item = item
    }
}

final class SettingRowContentView:
    UIControl,
    Touchable,
    ContainsSwitch
{
    struct Item:
        Identifiable,
        Equatable
    {
        enum Accessory: Equatable {
            case none
            case detail(String)
            case toggle(Bool)
        }

        enum Role: Equatable {
            case normal
            case destructive
        }

        let id: SettingRowID
        let title: String
        let accessory: Accessory
        let role: Role
    }

    var item: Item? {
        didSet {
            guard item != oldValue else {
                return
            }
            applyItem()
        }
    }

    let switchToggleEvent =
        ComponentEvent<Bool>()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = .hcFont(
            .semiBold,
            size: 18
        )
        return label
    }()

    private let detailLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = .hcFont(
            .extraBold,
            size: 16
        )
        label.textColor = .mainWhite
        return label
    }()

    private let toggleSwitch:
        UISwitch = {
            let toggleSwitch =
                UISwitch()
            toggleSwitch.tintColor =
                .systemBlue
            return toggleSwitch
        }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
        configureLayout()
        toggleSwitch.addTarget(
            self,
            action:
                #selector(
                    didChangeToggle
                ),
            for: .valueChanged
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError(
            "init(coder:)는 지원하지 않습니다."
        )
    }

    override var isHighlighted: Bool {
        didSet {
            alpha = isHighlighted
                ? 0.55
                : 1
        }
    }

    private func configureView() {
        backgroundColor = .clear
        isAccessibilityElement = true

        [
            titleLabel,
            detailLabel,
            toggleSwitch,
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints =
                false
            addSubview($0)
        }
    }

    private func configureLayout() {
        NSLayoutConstraint.activate([
            heightAnchor.constraint(
                equalToConstant: 52
            ),
            titleLabel.leadingAnchor
                .constraint(
                    equalTo:
                        leadingAnchor,
                    constant: 20
                ),
            titleLabel.centerYAnchor
                .constraint(
                    equalTo:
                        centerYAnchor
                ),
            titleLabel.trailingAnchor
                .constraint(
                    lessThanOrEqualTo:
                        detailLabel
                            .leadingAnchor,
                    constant: -12
                ),
            titleLabel.trailingAnchor
                .constraint(
                    lessThanOrEqualTo:
                        toggleSwitch
                            .leadingAnchor,
                    constant: -12
                ),
            detailLabel.centerYAnchor
                .constraint(
                    equalTo:
                        centerYAnchor
                ),
            detailLabel.trailingAnchor
                .constraint(
                    equalTo:
                        trailingAnchor,
                    constant: -20
                ),
            toggleSwitch.centerYAnchor
                .constraint(
                    equalTo:
                        centerYAnchor
                ),
            toggleSwitch.trailingAnchor
                .constraint(
                    equalTo:
                        trailingAnchor,
                    constant: -20
                ),
        ])
    }

    private func applyItem() {
        guard let item else {
            titleLabel.text = nil
            detailLabel.text = nil
            detailLabel.isHidden = true
            toggleSwitch.isHidden = true
            accessibilityLabel = nil
            return
        }

        titleLabel.text = item.title
        titleLabel.textColor =
            item.role == .destructive
            ? .systemRed
            : .mainWhite

        switch item.accessory {
        case .none:
            detailLabel.isHidden = true
            toggleSwitch.isHidden = true
            accessibilityValue = nil

        case let .detail(detail):
            detailLabel.text = detail
            detailLabel.isHidden = false
            toggleSwitch.isHidden = true
            accessibilityValue = detail

        case let .toggle(isOn):
            detailLabel.isHidden = true
            toggleSwitch.isHidden = false
            toggleSwitch.setOn(
                isOn,
                animated: false
            )
            accessibilityValue = isOn
                ? "켬"
                : "끔"
        }

        accessibilityLabel = item.title
        accessibilityTraits = .button
    }

    @objc
    private func didChangeToggle() {
        switchToggleEvent.send(
            toggleSwitch.isOn
        )
    }
}

struct SettingSectionHeaderComponent:
    Component
{
    typealias Item =
        SettingSectionHeaderContentView.Item

    let item: Item

    var estimatedHeight: CGFloat {
        38
    }

    func createContent()
        -> SettingSectionHeaderContentView
    {
        SettingSectionHeaderContentView()
    }

    func render(
        context _: ComponentContext,
        content:
            SettingSectionHeaderContentView
    ) {
        content.item = item
    }
}

final class SettingSectionHeaderContentView:
    UIView
{
    struct Item:
        Identifiable,
        Equatable
    {
        let id: String
        let title: String
    }

    var item: Item? {
        didSet {
            guard item != oldValue else {
                return
            }
            titleLabel.text =
                item?.title
        }
    }

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .hcFont(
            .semiBold,
            size: 14
        )
        label.textColor = .gray
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        titleLabel
            .translatesAutoresizingMaskIntoConstraints =
            false
        addSubview(titleLabel)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(
                equalToConstant: 38
            ),
            titleLabel.leadingAnchor
                .constraint(
                    equalTo:
                        leadingAnchor,
                    constant: 20
                ),
            titleLabel.trailingAnchor
                .constraint(
                    lessThanOrEqualTo:
                        trailingAnchor,
                    constant: -20
                ),
            titleLabel.bottomAnchor
                .constraint(
                    equalTo:
                        bottomAnchor,
                    constant: -6
                ),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError(
            "init(coder:)는 지원하지 않습니다."
        )
    }
}
