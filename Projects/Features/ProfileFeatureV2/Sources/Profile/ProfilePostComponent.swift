import CollectionViewAdapter
import Domain
import DSKit
import Kingfisher
import UIKit

enum ProfilePostImageRequest {
    static func options(
        targetWidth: CGFloat
    ) -> KingfisherOptionsInfo {
        let width = max(
            targetWidth,
            1
        )
        let processor =
            DownsamplingImageProcessor(
                size: CGSize(
                    width: width,
                    height: width * 1.5
                )
            )

        return [
            .processor(processor),
            .backgroundDecode,
            .scaleFactor(
                UIScreen.main.scale
            ),
            .cacheOriginalImage,
        ]
    }
}

struct ProfilePostComponent: Component {
    typealias Item =
        ProfilePostContentView.Item

    let post: Post
    let item: Item

    init(
        post: Post,
        targetWidth: CGFloat =
            UIScreen.main.bounds.width / 3
    ) {
        self.post = post
        item = Item(
            id: post.postId,
            imageURL: post.imageURL,
            targetWidth: targetWidth
        )
    }

    var estimatedHeight: CGFloat {
        item.targetWidth * 1.5
    }

    func createContent()
        -> ProfilePostContentView
    {
        ProfilePostContentView()
    }

    func render(
        context _: ComponentContext,
        content: ProfilePostContentView
    ) {
        content.item = item
    }
}

final class ProfilePostContentView:
    UIView,
    Touchable
{
    struct Item:
        Identifiable,
        Equatable
    {
        let id: String
        let imageURL: String
        let targetWidth: CGFloat
    }

    var item: Item? {
        didSet {
            guard item != oldValue else {
                return
            }
            applyItem()
        }
    }

    private let imageView:
        UIImageView = {
            let imageView =
                UIImageView()
            imageView.contentMode =
                .scaleAspectFill
            imageView.clipsToBounds =
                true
            imageView.backgroundColor =
                .gray500
            return imageView
        }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
        enablePressedEffect(
            scale: 0.98
        )
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

        imageView
            .translatesAutoresizingMaskIntoConstraints =
            false
        addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(
                equalTo: topAnchor
            ),
            imageView.leadingAnchor.constraint(
                equalTo: leadingAnchor
            ),
            imageView.trailingAnchor.constraint(
                equalTo: trailingAnchor
            ),
            imageView.bottomAnchor.constraint(
                equalTo: bottomAnchor
            ),
            imageView.heightAnchor.constraint(
                equalTo:
                    imageView.widthAnchor,
                multiplier: 1.5
            ),
        ])
    }

    private func applyItem() {
        imageView.kf.cancelDownloadTask()
        imageView.image = nil

        guard
            let item,
            let url = URL(
                string: item.imageURL
            )
        else {
            accessibilityLabel = nil
            return
        }

        accessibilityLabel =
            "프로필 게시물"

        imageView.kf.setImage(
            with: url,
            options:
                ProfilePostImageRequest
                    .options(
                        targetWidth:
                            item.targetWidth
                    )
        )
    }
}
