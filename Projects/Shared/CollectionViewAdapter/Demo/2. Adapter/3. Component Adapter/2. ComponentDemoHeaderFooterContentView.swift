import CollectionViewAdapter
import UIKit

enum ComponentDemoTextStyle: Equatable {
    case header
    case footer
}

enum ComponentDemoTextAppearance: Equatable {
    case connected
    case plain
}

/// Section의 header와 footer에서 공통으로 사용하는 UIView입니다.
final class ComponentDemoTextContentView: UIView {
    struct Item: Identifiable, Equatable {
        let id: String
        let text: String
        let style: ComponentDemoTextStyle
        let appearance: ComponentDemoTextAppearance
        let horizontalInset: CGFloat

        init(
            id: String,
            text: String,
            style: ComponentDemoTextStyle,
            appearance: ComponentDemoTextAppearance = .connected,
            horizontalInset: CGFloat = 20
        ) {
            self.id = id
            self.text = text
            self.style = style
            self.appearance = appearance
            self.horizontalInset = horizontalInset
        }
    }

    var item: Item? {
        didSet {
            guard item != oldValue else {
                return
            }
            applyItem()
        }
    }

    private let surfaceView = UIView()
    private let label = UILabel()

    private var surfaceLeadingConstraint: NSLayoutConstraint!
    private var surfaceTrailingConstraint: NSLayoutConstraint!
    private var labelTopConstraint: NSLayoutConstraint!
    private var labelBottomConstraint: NSLayoutConstraint!

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
        configureLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:)는 지원하지 않습니다.")
    }

    /// Component가 전달한 최신 Item을 반영합니다.
    private func applyItem() {
        guard let item else {
            label.text = nil
            return
        }

        label.text = item.text
        surfaceView.layer.masksToBounds = true
        surfaceLeadingConstraint.constant =
            item.horizontalInset
        surfaceTrailingConstraint.constant =
            -item.horizontalInset

        switch item.style {
        case .header:
            label.font = UIFontMetrics(forTextStyle: .title2)
                .scaledFont(
                    for: .systemFont(
                        ofSize: 22,
                        weight: .bold
                    )
                )
            label.textColor = ComponentDemoStyle.textPrimary
            labelTopConstraint.constant = 24
            labelBottomConstraint.constant = -12

        case .footer:
            label.font = UIFontMetrics(forTextStyle: .caption1)
                .scaledFont(
                    for: .systemFont(
                        ofSize: 13,
                        weight: .medium
                    )
                )
            label.textColor = ComponentDemoStyle.textSecondary
            labelTopConstraint.constant = 14
            labelBottomConstraint.constant = -18
        }

        switch item.appearance {
        case .connected:
            surfaceView.backgroundColor =
                ComponentDemoStyle.surface
            surfaceView.layer.cornerRadius =
                ComponentDemoStyle.cardCornerRadius
            surfaceView.layer.maskedCorners =
                connectedCorners(for: item.style)

        case .plain:
            surfaceView.backgroundColor = .clear
            surfaceView.layer.cornerRadius = 0
            surfaceView.layer.maskedCorners = []
        }
    }

    private func connectedCorners(
        for style: ComponentDemoTextStyle
    ) -> CACornerMask {
        switch style {
        case .header:
            return [
                .layerMinXMinYCorner,
                .layerMaxXMinYCorner
            ]

        case .footer:
            return [
                .layerMinXMaxYCorner,
                .layerMaxXMaxYCorner
            ]
        }
    }

    private func configureView() {
        backgroundColor = .clear
        surfaceView.backgroundColor = ComponentDemoStyle.surface
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
    }

    private func configureLayout() {
        surfaceView.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false

        addSubview(surfaceView)
        surfaceView.addSubview(label)

        labelTopConstraint = label.topAnchor.constraint(
            equalTo: surfaceView.topAnchor
        )
        labelBottomConstraint = label.bottomAnchor.constraint(
            equalTo: surfaceView.bottomAnchor
        )

        surfaceLeadingConstraint =
            surfaceView.leadingAnchor.constraint(
                equalTo: leadingAnchor
            )
        surfaceTrailingConstraint =
            surfaceView.trailingAnchor.constraint(
                equalTo: trailingAnchor
            )

        NSLayoutConstraint.activate([
            surfaceLeadingConstraint,
            surfaceTrailingConstraint,
            surfaceView.topAnchor.constraint(equalTo: topAnchor),
            surfaceView.bottomAnchor.constraint(equalTo: bottomAnchor),

            label.leadingAnchor.constraint(
                equalTo: surfaceView.leadingAnchor,
                constant: 20
            ),
            label.trailingAnchor.constraint(
                equalTo: surfaceView.trailingAnchor,
                constant: -20
            ),
            labelTopConstraint,
            labelBottomConstraint
        ])
    }
}
