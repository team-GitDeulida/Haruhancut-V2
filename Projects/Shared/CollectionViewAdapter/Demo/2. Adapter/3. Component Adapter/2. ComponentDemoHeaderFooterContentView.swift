import CollectionViewAdapter
import UIKit

/// Section의 header와 footer에서 공통으로 사용하는 UIView입니다.
final class ComponentDemoTextContentView: UIView {
    struct Item: Identifiable, Equatable {
        enum Style: Equatable {
            case header
            case footer
        }

        let id: String
        let text: String
        let style: Style
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
        surfaceView.layer.cornerRadius =
            ComponentDemoStyle.cardCornerRadius
        surfaceView.layer.masksToBounds = true

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
            surfaceView.layer.maskedCorners = [
                .layerMinXMinYCorner,
                .layerMaxXMinYCorner,
            ]

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
            surfaceView.layer.maskedCorners = [
                .layerMinXMaxYCorner,
                .layerMaxXMaxYCorner,
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

            label.leadingAnchor.constraint(
                equalTo: surfaceView.leadingAnchor,
                constant: 20
            ),
            label.trailingAnchor.constraint(
                equalTo: surfaceView.trailingAnchor,
                constant: -20
            ),
            labelTopConstraint,
            labelBottomConstraint,
        ])
    }
}
