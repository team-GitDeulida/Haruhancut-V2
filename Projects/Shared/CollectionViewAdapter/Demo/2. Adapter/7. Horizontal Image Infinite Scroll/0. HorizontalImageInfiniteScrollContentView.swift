import UIKit

/// 서로 다른 스크롤 방향을 사용하는 Section의 상태를 표시합니다.
@MainActor
final class MixedDirectionSectionHeaderContentView: UIView {
    struct Item: Identifiable, Equatable {
        let id: String
        let title: String
        let description: String
        let loadedCount: Int
        let isLoading: Bool
        let contentHorizontalInset: CGFloat
    }

    var item: Item? {
        didSet {
            guard item != oldValue else {
                return
            }
            applyItem()
        }
    }

    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let countLabel = UILabel()
    private let textStackView = UIStackView()
    private let activityIndicator = UIActivityIndicatorView(
        style: .medium
    )
    private lazy var textStackViewLeadingConstraint =
        textStackView.leadingAnchor.constraint(
            equalTo: leadingAnchor
        )
    private lazy var activityIndicatorTrailingConstraint =
        activityIndicator.trailingAnchor.constraint(
            equalTo: trailingAnchor
        )

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
        configureLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:)는 지원하지 않습니다.")
    }

    private func applyItem() {
        guard let item else {
            titleLabel.text = nil
            descriptionLabel.text = nil
            countLabel.text = nil
            activityIndicator.stopAnimating()
            return
        }

        titleLabel.text = item.title
        descriptionLabel.text = item.description
        countLabel.text = "\(item.loadedCount)개"
        textStackViewLeadingConstraint.constant =
            item.contentHorizontalInset
        activityIndicatorTrailingConstraint.constant =
            -item.contentHorizontalInset

        if item.isLoading {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }

        accessibilityLabel =
            "\(item.title), \(item.description), \(item.loadedCount)개"
    }

    private func configureView() {
        backgroundColor = .systemGroupedBackground

        titleLabel.font = .preferredFont(
            forTextStyle: .headline
        )
        titleLabel.textColor = .label
        titleLabel.adjustsFontForContentSizeCategory = true

        descriptionLabel.font = .preferredFont(
            forTextStyle: .caption1
        )
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.adjustsFontForContentSizeCategory =
            true

        countLabel.font = .monospacedDigitSystemFont(
            ofSize: 13,
            weight: .semibold
        )
        countLabel.textColor = .secondaryLabel

        textStackView.axis = .vertical
        textStackView.spacing = 3
        textStackView.addArrangedSubview(titleLabel)
        textStackView.addArrangedSubview(descriptionLabel)

        activityIndicator.color = .secondaryLabel
        activityIndicator.hidesWhenStopped = true
    }

    private func configureLayout() {
        textStackView.translatesAutoresizingMaskIntoConstraints =
            false
        countLabel.translatesAutoresizingMaskIntoConstraints =
            false
        activityIndicator.translatesAutoresizingMaskIntoConstraints =
            false

        addSubview(textStackView)
        addSubview(countLabel)
        addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            textStackViewLeadingConstraint,
            textStackView.centerYAnchor.constraint(
                equalTo: centerYAnchor
            ),
            textStackView.trailingAnchor.constraint(
                lessThanOrEqualTo: countLabel.leadingAnchor,
                constant: -12
            ),

            activityIndicatorTrailingConstraint,
            activityIndicator.centerYAnchor.constraint(
                equalTo: centerYAnchor
            ),

            countLabel.trailingAnchor.constraint(
                equalTo: activityIndicator.leadingAnchor,
                constant: -8
            ),
            countLabel.centerYAnchor.constraint(
                equalTo: centerYAnchor
            ),
        ])
    }
}

/// 가로 무한 스크롤에서 원격 이미지를 카드 형태로 표시합니다.
@MainActor
final class HorizontalImageInfiniteScrollContentView:
    UIView
{
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

    private let cardView = UIView()
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let sourceLabel = UILabel()
    private let textStackView = UIStackView()

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
        imageView.image = UIImage(systemName: "photo")
        imageView.tintColor = .tertiaryLabel
        imageView.backgroundColor = .secondarySystemFill

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

            self.imageView.image = image
            self.imageView.backgroundColor = .clear
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
        backgroundColor = .clear

        cardView.backgroundColor =
            .secondarySystemGroupedBackground
        cardView.layer.cornerRadius = 20
        cardView.layer.cornerCurve = .continuous
        cardView.layer.borderWidth =
            1 / UIScreen.main.scale
        cardView.layer.borderColor =
            UIColor.separator.cgColor
        cardView.clipsToBounds = true

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.preferredSymbolConfiguration =
            UIImage.SymbolConfiguration(
                pointSize: 30,
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
        textStackView.spacing = 5
        textStackView.addArrangedSubview(titleLabel)
        textStackView.addArrangedSubview(subtitleLabel)
        textStackView.addArrangedSubview(sourceLabel)
    }

    private func configureLayout() {
        cardView.translatesAutoresizingMaskIntoConstraints =
            false
        imageView.translatesAutoresizingMaskIntoConstraints =
            false
        textStackView.translatesAutoresizingMaskIntoConstraints =
            false

        addSubview(cardView)
        cardView.addSubview(imageView)
        cardView.addSubview(textStackView)

        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(
                equalTo: leadingAnchor
            ),
            cardView.trailingAnchor.constraint(
                equalTo: trailingAnchor
            ),
            cardView.topAnchor.constraint(
                equalTo: topAnchor
            ),
            cardView.bottomAnchor.constraint(
                equalTo: bottomAnchor
            ),

            imageView.leadingAnchor.constraint(
                equalTo: cardView.leadingAnchor
            ),
            imageView.trailingAnchor.constraint(
                equalTo: cardView.trailingAnchor
            ),
            imageView.topAnchor.constraint(
                equalTo: cardView.topAnchor
            ),
            imageView.heightAnchor.constraint(
                equalToConstant: 200
            ),

            textStackView.leadingAnchor.constraint(
                equalTo: cardView.leadingAnchor,
                constant: 16
            ),
            textStackView.trailingAnchor.constraint(
                equalTo: cardView.trailingAnchor,
                constant: -16
            ),
            textStackView.topAnchor.constraint(
                equalTo: imageView.bottomAnchor,
                constant: 14
            ),
            textStackView.bottomAnchor.constraint(
                lessThanOrEqualTo: cardView.bottomAnchor,
                constant: -14
            ),
        ])
    }
}
