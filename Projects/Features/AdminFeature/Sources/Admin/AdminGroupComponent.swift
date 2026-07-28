import CollectionViewAdapter
import Domain
import DSKit
import UIKit

struct AdminGroupComponent:
    Component
{
    typealias Item =
        AdminGroupContentView.Item

    let group:
        AdminGroupSummary
    let item: Item

    init(
        group:
            AdminGroupSummary,
        metricsText: String,
        latestPostText: String
    ) {
        self.group = group
        item = Item(
            id: group.groupId,
            groupName:
                group.groupName,
            groupIDText:
                group.groupId,
            metricsText:
                metricsText,
            latestPostText:
                latestPostText
        )
    }

    var estimatedHeight:
        CGFloat
    {
        150
    }

    func createContent()
        -> AdminGroupContentView
    {
        AdminGroupContentView()
    }

    func render(
        context _:
            ComponentContext,
        content:
            AdminGroupContentView
    ) {
        content.item = item
    }
}

final class AdminGroupContentView:
    UIView,
    Touchable,
    Pressable
{
    struct Item:
        Identifiable,
        Equatable
    {
        let id: String
        let groupName: String
        let groupIDText: String
        let metricsText: String
        let latestPostText: String
    }

    var item: Item? {
        didSet {
            guard item != oldValue
            else {
                return
            }
            applyItem()
        }
    }

    private let iconView:
        UIImageView = {
            let imageView =
                UIImageView(
                    image:
                        UIImage(
                            systemName:
                                "person.3.fill"
                        )
                )
            imageView.tintColor =
                .mainWhite
            imageView.contentMode =
                .scaleAspectFit
            return imageView
        }()

    private let iconBackgroundView:
        UIView = {
            let view = UIView()
            view.backgroundColor =
                .gray300
            view.layer.cornerRadius =
                22
            return view
        }()

    private let titleLabel:
        UILabel = {
            let label = UILabel()
            label.font =
                .hcFont(
                    .bold,
                    size: 18
                )
            label.textColor =
                .mainWhite
            label.numberOfLines = 1
            return label
        }()

    private let groupIDLabel:
        UILabel = {
            let label = UILabel()
            label.font =
                .hcFont(
                    .medium,
                    size: 12
                )
            label.textColor = .gray
            label.numberOfLines = 1
            label.lineBreakMode =
                .byTruncatingMiddle
            return label
        }()

    private let metricsLabel:
        UILabel = {
            let label = UILabel()
            label.font =
                .hcFont(
                    .medium,
                    size: 14
                )
            label.textColor =
                .mainWhite
            label.numberOfLines = 2
            return label
        }()

    private let latestPostLabel:
        UILabel = {
            let label = UILabel()
            label.font =
                .hcFont(
                    .medium,
                    size: 13
                )
            label.textColor = .gray
            label.numberOfLines = 1
            return label
        }()

    private let disclosureView:
        UIImageView = {
            let imageView =
                UIImageView(
                    image:
                        UIImage(
                            systemName:
                                "chevron.right"
                        )
                )
            imageView.tintColor = .gray
            imageView.contentMode =
                .scaleAspectFit
            return imageView
        }()

    private lazy var titleStack:
        UIStackView = {
            let stackView =
                UIStackView(
                    arrangedSubviews: [
                        titleLabel,
                        groupIDLabel,
                    ]
                )
            stackView.axis = .vertical
            stackView.alignment =
                .leading
            stackView.spacing = 4
            return stackView
        }()

    private lazy var headerStack:
        UIStackView = {
            let stackView =
                UIStackView(
                    arrangedSubviews: [
                        iconBackgroundView,
                        titleStack,
                        disclosureView,
                    ]
                )
            stackView.axis =
                .horizontal
            stackView.alignment =
                .center
            stackView.spacing = 12
            return stackView
        }()

    private lazy var contentStack:
        UIStackView = {
            let stackView =
                UIStackView(
                    arrangedSubviews: [
                        headerStack,
                        metricsLabel,
                        latestPostLabel,
                    ]
                )
            stackView.axis =
                .vertical
            stackView.alignment =
                .fill
            stackView.spacing = 12
            return stackView
        }()

    override init(
        frame: CGRect
    ) {
        super.init(frame: frame)
        configureView()
        configureLayout()
    }

    @available(*, unavailable)
    required init?(
        coder: NSCoder
    ) {
        fatalError(
            "init(coder:)는 지원하지 않습니다."
        )
    }

    private func configureView() {
        backgroundColor = .gray500
        layer.cornerRadius = 20
        clipsToBounds = true
        isAccessibilityElement = true
        accessibilityTraits = .button

        [
            contentStack,
            iconView,
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints =
                false
        }
        addSubview(contentStack)
        iconBackgroundView.addSubview(
            iconView
        )
    }

    private func configureLayout() {
        NSLayoutConstraint.activate([
            contentStack.topAnchor
                .constraint(
                    equalTo: topAnchor,
                    constant: 16
                ),
            contentStack.leadingAnchor
                .constraint(
                    equalTo: leadingAnchor,
                    constant: 16
                ),
            contentStack.trailingAnchor
                .constraint(
                    equalTo: trailingAnchor,
                    constant: -16
                ),
            contentStack.bottomAnchor
                .constraint(
                    equalTo: bottomAnchor,
                    constant: -16
                ),

            iconBackgroundView.widthAnchor
                .constraint(
                    equalToConstant: 44
                ),
            iconBackgroundView.heightAnchor
                .constraint(
                    equalToConstant: 44
                ),
            iconView.centerXAnchor
                .constraint(
                    equalTo:
                        iconBackgroundView
                            .centerXAnchor
                ),
            iconView.centerYAnchor
                .constraint(
                    equalTo:
                        iconBackgroundView
                            .centerYAnchor
                ),
            iconView.widthAnchor
                .constraint(
                    equalToConstant: 22
                ),
            iconView.heightAnchor
                .constraint(
                    equalToConstant: 22
                ),
            disclosureView.widthAnchor
                .constraint(
                    equalToConstant: 12
                ),
        ])
    }

    private func applyItem() {
        guard let item
        else {
            return
        }
        titleLabel.text =
            item.groupName
        groupIDLabel.text =
            item.groupIDText
        metricsLabel.text =
            item.metricsText
        latestPostLabel.text =
            item.latestPostText
        accessibilityLabel = [
            item.groupName,
            item.metricsText,
            item.latestPostText,
        ].joined(separator: ", ")
    }
}
