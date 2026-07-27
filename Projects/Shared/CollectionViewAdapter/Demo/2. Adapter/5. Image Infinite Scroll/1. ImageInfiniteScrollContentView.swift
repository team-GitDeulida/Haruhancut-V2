import UIKit

/// Prefetch한 원격 이미지와 게시물 정보를 함께 표시하는 Content입니다.
@MainActor
final class ImageInfiniteScrollContentView: UIView {
    struct Item: Identifiable, Equatable {
        let id: Int
        let title: String
        let subtitle: String
        let imageURL: URL
        let page: Int
    }

    var item: Item? {
        didSet {
            guard item != oldValue else {
                return
            }

            cancelCurrentImageRequest()
            applyItem()
        }
    }

    private let imageLoader:
        ImageInfiniteScrollImageLoader
    private var imageRequestID: UUID?

    private let thumbnailImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let sourceLabel = UILabel()
    private let textStackView = UIStackView()
    private let separatorView = UIView()

    init(imageLoader: ImageInfiniteScrollImageLoader) {
        self.imageLoader = imageLoader
        super.init(frame: .zero)
        configureView()
        configureLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:)는 지원하지 않습니다.")
    }

    private func applyItem() {
        thumbnailImageView.image = UIImage(
            systemName: "photo"
        )
        thumbnailImageView.tintColor = .tertiaryLabel
        thumbnailImageView.backgroundColor =
            .secondarySystemFill

        guard let item else {
            titleLabel.text = nil
            subtitleLabel.text = nil
            sourceLabel.text = nil
            return
        }

        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
        sourceLabel.text =
            "\(item.page)페이지 · 이미지 준비 중"

        let imageURL = item.imageURL
        imageRequestID = imageLoader.requestImage(
            for: imageURL
        ) { [weak self] image, source in
            guard
                let self,
                self.item?.imageURL == imageURL
            else {
                return
            }

            self.imageRequestID = nil
            guard let image else {
                self.sourceLabel.text =
                    "\(item.page)페이지 · 불러오기 실패"
                return
            }

            self.thumbnailImageView.image = image
            self.thumbnailImageView.backgroundColor = .clear
            switch source {
            case .memoryCache:
                self.sourceLabel.text =
                    "\(item.page)페이지 · prefetch cache"
            case .network:
                self.sourceLabel.text =
                    "\(item.page)페이지 · network load"
            case nil:
                self.sourceLabel.text =
                    "\(item.page)페이지"
            }
        }

        accessibilityLabel =
            "\(item.title), \(item.subtitle), \(item.page)페이지"
    }

    private func cancelCurrentImageRequest() {
        guard let imageRequestID else {
            return
        }

        imageLoader.cancelImageRequest(imageRequestID)
        self.imageRequestID = nil
    }

    private func configureView() {
        backgroundColor = .systemBackground

        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.clipsToBounds = true
        thumbnailImageView.layer.cornerRadius = 12
        thumbnailImageView.preferredSymbolConfiguration =
            UIImage.SymbolConfiguration(
                pointSize: 24,
                weight: .regular
            )

        titleLabel.font = .preferredFont(
            forTextStyle: .headline
        )
        titleLabel.textColor = .label
        titleLabel.adjustsFontForContentSizeCategory = true

        subtitleLabel.font = .preferredFont(
            forTextStyle: .subheadline
        )
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 2
        subtitleLabel.adjustsFontForContentSizeCategory = true

        sourceLabel.font = .preferredFont(
            forTextStyle: .caption2
        )
        sourceLabel.textColor = .tertiaryLabel
        sourceLabel.adjustsFontForContentSizeCategory = true

        textStackView.axis = .vertical
        textStackView.spacing = 4
        textStackView.addArrangedSubview(titleLabel)
        textStackView.addArrangedSubview(subtitleLabel)
        textStackView.addArrangedSubview(sourceLabel)

        separatorView.backgroundColor = .separator
    }

    private func configureLayout() {
        thumbnailImageView.translatesAutoresizingMaskIntoConstraints =
            false
        textStackView.translatesAutoresizingMaskIntoConstraints =
            false
        separatorView.translatesAutoresizingMaskIntoConstraints =
            false

        addSubview(thumbnailImageView)
        addSubview(textStackView)
        addSubview(separatorView)

        NSLayoutConstraint.activate([
            thumbnailImageView.leadingAnchor.constraint(
                equalTo: leadingAnchor,
                constant: 16
            ),
            thumbnailImageView.topAnchor.constraint(
                equalTo: topAnchor,
                constant: 12
            ),
            thumbnailImageView.bottomAnchor.constraint(
                equalTo: bottomAnchor,
                constant: -12
            ),
            thumbnailImageView.widthAnchor.constraint(
                equalToConstant: 112
            ),
            thumbnailImageView.heightAnchor.constraint(
                equalToConstant: 84
            ),

            textStackView.leadingAnchor.constraint(
                equalTo: thumbnailImageView.trailingAnchor,
                constant: 14
            ),
            textStackView.trailingAnchor.constraint(
                equalTo: trailingAnchor,
                constant: -16
            ),
            textStackView.centerYAnchor.constraint(
                equalTo: thumbnailImageView.centerYAnchor
            ),

            separatorView.leadingAnchor.constraint(
                equalTo: textStackView.leadingAnchor
            ),
            separatorView.trailingAnchor.constraint(
                equalTo: trailingAnchor
            ),
            separatorView.bottomAnchor.constraint(
                equalTo: bottomAnchor
            ),
            separatorView.heightAnchor.constraint(
                equalToConstant: 1 / UIScreen.main.scale
            ),
        ])
    }
}
