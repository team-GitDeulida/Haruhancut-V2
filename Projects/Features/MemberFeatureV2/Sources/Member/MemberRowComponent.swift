import CollectionViewAdapter
import Domain
import DSKit
import Kingfisher
import UIKit

enum MemberRowIdentifier:
    Hashable
{
    case invite
    case member(String)
}

enum MemberProfileImageRequest {
    static let targetSize =
        CGSize(
            width: 60,
            height: 60
        )

    static var options:
        KingfisherOptionsInfo
    {
        [
            .processor(
                DownsamplingImageProcessor(
                    size: targetSize
                )
            ),
            .backgroundDecode,
            .scaleFactor(
                UIScreen.main.scale
            ),
            .cacheOriginalImage,
        ]
    }
}

struct MemberRowComponent: Component {
    typealias Item =
        MemberRowContentView.Item

    let item: Item

    static var invite: Self {
        Self(
            item: Item(
                id: .invite,
                content: .invite
            )
        )
    }

    init(user: User) {
        item = Item(
            id: .member(user.uid),
            content: .member(
                nickname: user.nickname,
                profileImageURL:
                    user.profileImageURL
            )
        )
    }

    private init(item: Item) {
        self.item = item
    }

    var estimatedHeight: CGFloat {
        60
    }

    func createContent()
        -> MemberRowContentView
    {
        MemberRowContentView()
    }

    func render(
        context _: ComponentContext,
        content: MemberRowContentView
    ) {
        content.item = item
    }
}

final class MemberRowContentView:
    UIView,
    Touchable
{
    struct Item:
        Identifiable,
        Equatable
    {
        enum Content: Equatable {
            case invite
            case member(
                nickname: String,
                profileImageURL: String?
            )
        }

        let id: MemberRowIdentifier
        let content: Content
    }

    var item: Item? {
        didSet {
            guard item != oldValue else {
                return
            }
            applyItem()
        }
    }

    private let circleView: UIView = {
        let view = UIView()
        view.backgroundColor = .gray300
        view.clipsToBounds = true
        return view
    }()

    private let profileImageView:
        UIImageView = {
            let imageView =
                UIImageView()
            imageView.clipsToBounds =
                true
            imageView.contentMode =
                .scaleAspectFill
            imageView.tintColor = .gray
            return imageView
        }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font =
            .hcFont(
                .bold,
                size: 14
            )
        label.textColor = .mainWhite
        return label
    }()

    private lazy var contentStack:
        UIStackView = {
            let stackView =
                UIStackView(
                    arrangedSubviews: [
                        circleView,
                        nameLabel,
                    ]
                )
            stackView.axis = .horizontal
            stackView.alignment = .center
            stackView.spacing = 12
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
        isAccessibilityElement = true
        accessibilityTraits = .button

        [
            contentStack,
            profileImageView,
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints =
                false
        }
        addSubview(contentStack)
        circleView.addSubview(
            profileImageView
        )

        circleView.layer.cornerRadius = 30
        profileImageView.layer
            .cornerRadius = 30
    }

    private func configureLayout() {
        NSLayoutConstraint.activate([
            contentStack.topAnchor
                .constraint(
                    equalTo: topAnchor
                ),
            contentStack.leadingAnchor
                .constraint(
                    equalTo:
                        leadingAnchor
                ),
            contentStack.trailingAnchor
                .constraint(
                    equalTo:
                        trailingAnchor
                ),
            contentStack.bottomAnchor
                .constraint(
                    equalTo:
                        bottomAnchor
                ),

            circleView.widthAnchor
                .constraint(
                    equalToConstant: 60
                ),
            circleView.heightAnchor
                .constraint(
                    equalTo:
                        circleView
                            .widthAnchor
                ),

            profileImageView.topAnchor
                .constraint(
                    equalTo:
                        circleView
                            .topAnchor
                ),
            profileImageView.leadingAnchor
                .constraint(
                    equalTo:
                        circleView
                            .leadingAnchor
                ),
            profileImageView.trailingAnchor
                .constraint(
                    equalTo:
                        circleView
                            .trailingAnchor
                ),
            profileImageView.bottomAnchor
                .constraint(
                    equalTo:
                        circleView
                            .bottomAnchor
                ),
        ])
    }

    private func applyItem() {
        profileImageView.kf
            .cancelDownloadTask()
        profileImageView.image = nil
        profileImageView.contentMode =
            .scaleAspectFill
        profileImageView.tintColor = .gray
        circleView.backgroundColor =
            .gray300
        nameLabel.text = nil

        guard let item else {
            accessibilityLabel = nil
            return
        }

        switch item.content {
        case .invite:
            profileImageView
                .contentMode = .center
            profileImageView.image =
                UIImage(
                    systemName: "plus"
                )
            profileImageView.tintColor =
                .white
            circleView.backgroundColor =
                .gray
            nameLabel.text = ""
            accessibilityLabel =
                "그룹 멤버 초대"

        case let .member(
            nickname,
            profileImageURL
        ):
            nameLabel.text = nickname
            accessibilityLabel =
                "\(nickname) 프로필"

            guard
                let profileImageURL,
                let url = URL(
                    string:
                        profileImageURL
                )
            else {
                profileImageView.image =
                    UIImage(
                        systemName:
                            "person.fill"
                    )
                return
            }

            profileImageView.kf.setImage(
                with: url,
                options:
                    MemberProfileImageRequest
                        .options
            )
        }
    }
}
