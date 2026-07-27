import CollectionViewAdapter
import DSKit
import UIKit

struct MemberHeaderComponent: Component {
    typealias Item =
        MemberHeaderContentView.Item

    let item: Item

    init(memberCount: Int) {
        item = Item(
            id: "member-count-header",
            memberCount: memberCount
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
    UIView
{
    struct Item:
        Identifiable,
        Equatable
    {
        let id: String
        let memberCount: Int
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
        isAccessibilityElement = true
        accessibilityTraits = .header
        titleStack
            .translatesAutoresizingMaskIntoConstraints =
            false
        addSubview(titleStack)
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
                        trailingAnchor
                ),
            titleStack.bottomAnchor
                .constraint(
                    equalTo: bottomAnchor,
                    constant:
                        -Layout.bottomInset
                ),
        ])
    }

    private func applyItem() {
        guard let item else {
            countLabel.text = nil
            accessibilityLabel = nil
            return
        }

        countLabel.text = String(
            format:
                LocalizationKey
                    .memberFamilyCountValue
                    .localized,
            item.memberCount
        )
        accessibilityLabel =
            "\(titleLabel.text ?? "") \(countLabel.text ?? "")"
    }
}
