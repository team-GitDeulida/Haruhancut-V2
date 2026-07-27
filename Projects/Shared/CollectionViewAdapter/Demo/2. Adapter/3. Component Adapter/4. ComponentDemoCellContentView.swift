import CollectionViewAdapter
import UIKit

/// 목록의 한 행을 실제로 표시하는 UIView입니다.
///
/// `Touchable`, `ContainsButton`, `ContainsSwitch`를 채택해 Component
/// modifier가 필요한 이벤트만 선택적으로 연결할 수 있게 합니다.
final class ComponentDemoRowContentView:
    UIControl,
    Touchable,
    ContainsButton,
    ContainsSwitch
{
    struct Item: Identifiable, Equatable {
        enum Accessory: Equatable {
            case button(String)
            case toggle(isOn: Bool)
            case chevron
        }

        enum Appearance: Equatable {
            case connectedCard
            case standaloneCard
        }

        let id: String
        let title: String
        let subtitle: String?
        let symbolName: String
        let accessory: Accessory
        let appearance: Appearance
    }

    var item: Item? {
        didSet {
            guard item != oldValue else {
                return
            }
            applyItem()
        }
    }

    let buttonTapEvent = ComponentEvent<Void>()
    let switchToggleEvent = ComponentEvent<Bool>()

    private let surfaceView = UIView()
    private let symbolBackgroundView = UIView()
    private let symbolView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let labelsStackView = UIStackView()
    private let spacerView = UIView()
    private let actionButton = UIButton(type: .system)
    private let toggle = UISwitch()
    private let chevronView = UIImageView(
        image: UIImage(systemName: "chevron.right")
    )
    private let rowStackView = UIStackView()
    private let separatorView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
        configureLayout()
        configureActions()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:)는 지원하지 않습니다.")
    }

    override var isHighlighted: Bool {
        didSet {
            surfaceView.alpha = isHighlighted ? 0.72 : 1
        }
    }

    /// Component가 전달한 최신 Item을 UIView에 반영합니다.
    private func applyItem() {
        guard let item else {
            titleLabel.text = nil
            subtitleLabel.text = nil
            subtitleLabel.isHidden = true
            symbolView.image = nil
            return
        }

        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
        subtitleLabel.isHidden = item.subtitle == nil
        symbolView.image = UIImage(
            systemName: item.symbolName
        )

        accessibilityLabel = [
            item.title,
            item.subtitle,
        ].compactMap { $0 }.joined(separator: ", ")

        apply(accessory: item.accessory)
        apply(appearance: item.appearance)
    }

    private func configureView() {
        backgroundColor = .clear
        accessibilityTraits = .button

        surfaceView.backgroundColor = ComponentDemoStyle.surface
        surfaceView.isUserInteractionEnabled = false

        symbolBackgroundView.backgroundColor =
            ComponentDemoStyle.accentBackground
        symbolBackgroundView.layer.cornerRadius = 14
        symbolBackgroundView.isUserInteractionEnabled = false

        symbolView.tintColor = ComponentDemoStyle.accent
        symbolView.contentMode = .scaleAspectFit
        symbolView.preferredSymbolConfiguration =
            UIImage.SymbolConfiguration(
                pointSize: 19,
                weight: .semibold
            )

        titleLabel.font = UIFontMetrics(forTextStyle: .body)
            .scaledFont(
                for: .systemFont(
                    ofSize: 17,
                    weight: .semibold
                )
            )
        titleLabel.textColor = ComponentDemoStyle.textPrimary
        titleLabel.adjustsFontForContentSizeCategory = true

        subtitleLabel.font = UIFontMetrics(forTextStyle: .subheadline)
            .scaledFont(
                for: .systemFont(
                    ofSize: 14,
                    weight: .regular
                )
            )
        subtitleLabel.textColor = ComponentDemoStyle.textSecondary
        subtitleLabel.adjustsFontForContentSizeCategory = true

        labelsStackView.axis = .vertical
        labelsStackView.spacing = 3
        labelsStackView.addArrangedSubview(titleLabel)
        labelsStackView.addArrangedSubview(subtitleLabel)

        var buttonConfiguration = UIButton.Configuration.filled()
        buttonConfiguration.baseBackgroundColor =
            ComponentDemoStyle.accentBackground
        buttonConfiguration.baseForegroundColor =
            ComponentDemoStyle.accent
        buttonConfiguration.cornerStyle = .capsule
        buttonConfiguration.contentInsets = NSDirectionalEdgeInsets(
            top: 8,
            leading: 13,
            bottom: 8,
            trailing: 13
        )
        actionButton.configuration = buttonConfiguration

        toggle.onTintColor = ComponentDemoStyle.switchOn

        chevronView.tintColor = ComponentDemoStyle.textSecondary
        chevronView.contentMode = .scaleAspectFit

        separatorView.backgroundColor = ComponentDemoStyle.separator
        separatorView.isUserInteractionEnabled = false

        rowStackView.axis = .horizontal
        rowStackView.alignment = .center
        rowStackView.spacing = 14
        rowStackView.addArrangedSubview(symbolBackgroundView)
        rowStackView.addArrangedSubview(labelsStackView)
        rowStackView.addArrangedSubview(spacerView)
        rowStackView.addArrangedSubview(actionButton)
        rowStackView.addArrangedSubview(toggle)
        rowStackView.addArrangedSubview(chevronView)
    }

    private func configureLayout() {
        surfaceView.translatesAutoresizingMaskIntoConstraints = false
        symbolBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        symbolView.translatesAutoresizingMaskIntoConstraints = false
        rowStackView.translatesAutoresizingMaskIntoConstraints = false
        separatorView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(surfaceView)
        symbolBackgroundView.addSubview(symbolView)
        addSubview(rowStackView)
        surfaceView.addSubview(separatorView)

        NSLayoutConstraint.activate([
            surfaceView.leadingAnchor.constraint(
                equalTo: leadingAnchor,
                constant: 20
            ),
            surfaceView.trailingAnchor.constraint(
                equalTo: trailingAnchor,
                constant: -20
            ),
            surfaceView.topAnchor.constraint(equalTo: topAnchor),
            surfaceView.bottomAnchor.constraint(equalTo: bottomAnchor),

            symbolBackgroundView.widthAnchor.constraint(
                equalToConstant: 44
            ),
            symbolBackgroundView.heightAnchor.constraint(
                equalToConstant: 44
            ),
            symbolView.centerXAnchor.constraint(
                equalTo: symbolBackgroundView.centerXAnchor
            ),
            symbolView.centerYAnchor.constraint(
                equalTo: symbolBackgroundView.centerYAnchor
            ),
            symbolView.widthAnchor.constraint(equalToConstant: 22),
            symbolView.heightAnchor.constraint(equalToConstant: 22),

            rowStackView.leadingAnchor.constraint(
                equalTo: surfaceView.leadingAnchor,
                constant: 18
            ),
            rowStackView.trailingAnchor.constraint(
                equalTo: surfaceView.trailingAnchor,
                constant: -18
            ),
            rowStackView.topAnchor.constraint(
                equalTo: surfaceView.topAnchor,
                constant: 14
            ),
            rowStackView.bottomAnchor.constraint(
                equalTo: surfaceView.bottomAnchor,
                constant: -14
            ),

            separatorView.leadingAnchor.constraint(
                equalTo: labelsStackView.leadingAnchor
            ),
            separatorView.trailingAnchor.constraint(
                equalTo: surfaceView.trailingAnchor,
                constant: -18
            ),
            separatorView.bottomAnchor.constraint(
                equalTo: surfaceView.bottomAnchor
            ),
            separatorView.heightAnchor.constraint(
                equalToConstant: 1 / UIScreen.main.scale
            ),

            chevronView.widthAnchor.constraint(equalToConstant: 12),
            spacerView.widthAnchor.constraint(
                greaterThanOrEqualToConstant: 0
            ),
        ])
    }

    private func configureActions() {
        actionButton.addTarget(
            self,
            action: #selector(didTapButton),
            for: .touchUpInside
        )
        toggle.addTarget(
            self,
            action: #selector(didChangeToggle),
            for: .valueChanged
        )
    }

    private func apply(
        accessory: Item.Accessory
    ) {
        actionButton.isHidden = true
        toggle.isHidden = true
        chevronView.isHidden = true

        switch accessory {
        case let .button(title):
            var configuration = actionButton.configuration
            configuration?.title = title
            actionButton.configuration = configuration
            actionButton.isHidden = false

        case let .toggle(isOn):
            toggle.setOn(isOn, animated: false)
            toggle.isHidden = false

        case .chevron:
            chevronView.isHidden = false
        }
    }

    private func apply(
        appearance: Item.Appearance
    ) {
        switch appearance {
        case .connectedCard:
            surfaceView.layer.cornerRadius = 0
            separatorView.isHidden = false

        case .standaloneCard:
            surfaceView.layer.cornerRadius =
                ComponentDemoStyle.cardCornerRadius
            separatorView.isHidden = true
        }

        surfaceView.layer.masksToBounds = true
    }

    @objc
    private func didTapButton() {
        buttonTapEvent.send(())
    }

    @objc
    private func didChangeToggle() {
        switchToggleEvent.send(toggle.isOn)
    }
}
