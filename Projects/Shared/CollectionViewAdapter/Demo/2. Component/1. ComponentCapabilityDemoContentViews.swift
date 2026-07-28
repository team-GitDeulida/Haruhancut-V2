import CollectionViewAdapter
import UIKit

/// capability 예제 카드의 공통 표현만 담당하는 Content 기반 클래스입니다.
///
/// 상호작용 capability는 이 타입에 두지 않고 각 concrete subclass가
/// 필요한 프로토콜 하나만 채택합니다.
class ComponentCapabilityCardContentView: UIView {
    var item: ComponentCapabilityDemoItem? {
        didSet {
            guard item != oldValue else {
                return
            }
            applyItem()
        }
    }

    private let symbolBackgroundView = UIView()
    private let symbolView = UIImageView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let codeLabel = UILabel()
    private let textStackView = UIStackView()
    private let accessoryStackView = UIStackView()
    private let contentStackView = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
        configureLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:)는 지원하지 않습니다.")
    }

    /// concrete capability가 사용할 accessory를 카드 오른쪽에 배치합니다.
    func installAccessory(_ view: UIView) {
        accessoryStackView.addArrangedSubview(view)
    }

    private func applyItem() {
        guard let item else {
            symbolView.image = nil
            titleLabel.text = nil
            descriptionLabel.text = nil
            codeLabel.text = nil
            accessibilityLabel = nil
            return
        }

        let kind = item.kind
        symbolView.image = UIImage(
            systemName: kind.symbolName
        )
        symbolView.tintColor = kind.accentColor
        symbolBackgroundView.backgroundColor =
            kind.accentColor.withAlphaComponent(0.14)
        titleLabel.text = kind.cardTitle
        descriptionLabel.text = kind.cardDescription
        codeLabel.text = kind.code
        codeLabel.textColor = kind.accentColor
        accessibilityLabel =
            "\(kind.title), \(kind.cardTitle), \(kind.cardDescription)"
    }

    private func configureView() {
        backgroundColor = .secondarySystemGroupedBackground
        layer.cornerRadius = 24
        layer.cornerCurve = .continuous
        layer.borderWidth = 1 / UIScreen.main.scale
        layer.borderColor = UIColor.separator.cgColor

        symbolBackgroundView.layer.cornerRadius = 16
        symbolBackgroundView.layer.cornerCurve = .continuous
        symbolBackgroundView.isUserInteractionEnabled = false

        symbolView.contentMode = .scaleAspectFit
        symbolView.preferredSymbolConfiguration =
            UIImage.SymbolConfiguration(
                pointSize: 23,
                weight: .semibold
            )
        symbolView.isUserInteractionEnabled = false

        titleLabel.font = .preferredFont(
            forTextStyle: .headline
        )
        titleLabel.textColor = .label
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 0

        descriptionLabel.font = .preferredFont(
            forTextStyle: .subheadline
        )
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.adjustsFontForContentSizeCategory =
            true
        descriptionLabel.numberOfLines = 0

        codeLabel.font = UIFontMetrics(
            forTextStyle: .caption1
        ).scaledFont(
            for: .monospacedSystemFont(
                ofSize: 12,
                weight: .semibold
            )
        )
        codeLabel.adjustsFontForContentSizeCategory = true
        codeLabel.numberOfLines = 0

        textStackView.axis = .vertical
        textStackView.spacing = 6
        textStackView.addArrangedSubview(titleLabel)
        textStackView.addArrangedSubview(descriptionLabel)
        textStackView.addArrangedSubview(codeLabel)

        accessoryStackView.axis = .vertical
        accessoryStackView.alignment = .center
        accessoryStackView.distribution = .equalCentering

        contentStackView.axis = .horizontal
        contentStackView.alignment = .center
        contentStackView.spacing = 14
        contentStackView.addArrangedSubview(
            symbolBackgroundView
        )
        contentStackView.addArrangedSubview(textStackView)
        contentStackView.addArrangedSubview(accessoryStackView)
    }

    private func configureLayout() {
        symbolBackgroundView.translatesAutoresizingMaskIntoConstraints =
            false
        symbolView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.translatesAutoresizingMaskIntoConstraints =
            false

        addSubview(contentStackView)
        symbolBackgroundView.addSubview(symbolView)

        textStackView.setContentCompressionResistancePriority(
            .defaultLow,
            for: .horizontal
        )
        accessoryStackView.setContentHuggingPriority(
            .required,
            for: .horizontal
        )

        NSLayoutConstraint.activate([
            symbolBackgroundView.widthAnchor.constraint(
                equalToConstant: 52
            ),
            symbolBackgroundView.heightAnchor.constraint(
                equalToConstant: 52
            ),
            symbolView.centerXAnchor.constraint(
                equalTo: symbolBackgroundView.centerXAnchor
            ),
            symbolView.centerYAnchor.constraint(
                equalTo: symbolBackgroundView.centerYAnchor
            ),
            symbolView.widthAnchor.constraint(equalToConstant: 28),
            symbolView.heightAnchor.constraint(equalToConstant: 28),

            contentStackView.leadingAnchor.constraint(
                equalTo: leadingAnchor,
                constant: 18
            ),
            contentStackView.trailingAnchor.constraint(
                equalTo: trailingAnchor,
                constant: -18
            ),
            contentStackView.topAnchor.constraint(
                equalTo: topAnchor,
                constant: 20
            ),
            contentStackView.bottomAnchor.constraint(
                equalTo: bottomAnchor,
                constant: -20
            ),
        ])
    }
}

/// Content 전체 탭만 지원하는 예제입니다.
final class TouchableDemoContentView:
    ComponentCapabilityCardContentView,
    Touchable
{
    private let touchImageView = UIImageView(
        image: UIImage(systemName: "hand.tap")
    )

    override init(frame: CGRect) {
        super.init(frame: frame)

        isAccessibilityElement = true
        accessibilityTraits = .button
        touchImageView.tintColor = .systemBlue
        touchImageView.preferredSymbolConfiguration =
            UIImage.SymbolConfiguration(
                pointSize: 24,
                weight: .medium
            )
        touchImageView.isUserInteractionEnabled = false
        installAccessory(touchImageView)

        NSLayoutConstraint.activate([
            touchImageView.widthAnchor.constraint(
                equalToConstant: 30
            ),
            touchImageView.heightAnchor.constraint(
                equalToConstant: 30
            ),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:)는 지원하지 않습니다.")
    }
}

/// 눌림 시각 효과만 지원하는 예제입니다.
final class PressableDemoContentView:
    ComponentCapabilityCardContentView,
    Pressable
{
    private let pressLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        pressLabel.text = "PRESS"
        pressLabel.textColor = .systemIndigo
        pressLabel.font = .monospacedSystemFont(
            ofSize: 11,
            weight: .bold
        )
        pressLabel.isUserInteractionEnabled = false
        installAccessory(pressLabel)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:)는 지원하지 않습니다.")
    }
}

/// Content 내부 UIButton 동작만 지원하는 예제입니다.
final class ContainsButtonDemoContentView:
    ComponentCapabilityCardContentView,
    ContainsButton
{
    let buttonTapEvent = ComponentEvent<Void>()

    private let actionButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)

        var configuration = UIButton.Configuration.filled()
        configuration.title = "실행"
        configuration.baseBackgroundColor = .systemOrange
        configuration.baseForegroundColor = .white
        configuration.cornerStyle = .capsule
        configuration.contentInsets = NSDirectionalEdgeInsets(
            top: 9,
            leading: 14,
            bottom: 9,
            trailing: 14
        )
        actionButton.configuration = configuration
        actionButton.addTarget(
            self,
            action: #selector(didTapButton),
            for: .touchUpInside
        )
        installAccessory(actionButton)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:)는 지원하지 않습니다.")
    }

    @objc
    private func didTapButton() {
        buttonTapEvent.send(())
    }
}

/// Content 내부 UISwitch 동작만 지원하는 예제입니다.
final class ContainsSwitchDemoContentView:
    ComponentCapabilityCardContentView,
    ContainsSwitch
{
    let switchToggleEvent = ComponentEvent<Bool>()

    private let toggle = UISwitch()

    override var item: ComponentCapabilityDemoItem? {
        didSet {
            guard item != oldValue, let item else {
                return
            }
            toggle.setOn(item.isOn, animated: false)
            accessibilityValue = item.isOn ? "켬" : "끔"
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        toggle.onTintColor = .systemGreen
        toggle.addTarget(
            self,
            action: #selector(didChangeToggle),
            for: .valueChanged
        )
        installAccessory(toggle)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:)는 지원하지 않습니다.")
    }

    @objc
    private func didChangeToggle() {
        switchToggleEvent.send(toggle.isOn)
    }
}
