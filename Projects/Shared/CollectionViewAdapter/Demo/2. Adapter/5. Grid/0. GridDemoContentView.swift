import CollectionViewAdapter
import UIKit

/// Grid의 한 칸에 사진 주제를 카드 형태로 표시합니다.
final class GridDemoContentView:
    UIControl,
    Touchable
{
    /// Grid 카드가 표시할 안정적인 ID와 화면 상태입니다.
    struct Item: Identifiable, Equatable {
        let id: String
        let title: String
        let subtitle: String
        let symbolName: String
        var isFavorite: Bool
    }

    /// Component가 전달한 최신 Item입니다.
    var item: Item? {
        didSet {
            guard item != oldValue else {
                return
            }
            applyItem()
        }
    }

    private let surfaceView = UIView()
    private let artworkView = UIView()
    private let symbolView = UIImageView()
    private let favoriteView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let textStackView = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
        configureLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:)는 지원하지 않습니다.")
    }

    override var isHighlighted: Bool {
        didSet {
            surfaceView.alpha = isHighlighted ? 0.72 : 1
            surfaceView.transform = isHighlighted
                ? CGAffineTransform(
                    scaleX: 0.98,
                    y: 0.98
                )
                : .identity
        }
    }

    /// Item의 표시 값과 선택 상태를 카드에 반영합니다.
    private func applyItem() {
        guard let item else {
            symbolView.image = nil
            titleLabel.text = nil
            subtitleLabel.text = nil
            favoriteView.image = nil
            accessibilityLabel = nil
            return
        }

        symbolView.image = UIImage(
            systemName: item.symbolName
        )
        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
        favoriteView.image = UIImage(
            systemName: item.isFavorite
                ? "heart.fill"
                : "heart"
        )
        favoriteView.tintColor = item.isFavorite
            ? .systemPink
            : .tertiaryLabel

        accessibilityLabel =
            "\(item.title), \(item.subtitle)"
        accessibilityValue = item.isFavorite
            ? "즐겨찾기"
            : "즐겨찾기 아님"
        accessibilityTraits = [
            .button,
            item.isFavorite ? .selected : [],
        ]
    }

    private func configureView() {
        backgroundColor = .clear
        isAccessibilityElement = true

        surfaceView.backgroundColor =
            .secondarySystemGroupedBackground
        surfaceView.layer.cornerRadius = 20
        surfaceView.layer.cornerCurve = .continuous
        surfaceView.layer.borderWidth =
            1 / UIScreen.main.scale
        surfaceView.layer.borderColor =
            UIColor.separator.cgColor
        surfaceView.isUserInteractionEnabled = false

        artworkView.backgroundColor =
            UIColor.systemYellow.withAlphaComponent(0.22)
        artworkView.layer.cornerRadius = 15
        artworkView.layer.cornerCurve = .continuous

        symbolView.tintColor = .label
        symbolView.contentMode = .scaleAspectFit
        symbolView.preferredSymbolConfiguration =
            UIImage.SymbolConfiguration(
                pointSize: 34,
                weight: .semibold
            )

        favoriteView.contentMode = .scaleAspectFit
        favoriteView.preferredSymbolConfiguration =
            UIImage.SymbolConfiguration(
                pointSize: 16,
                weight: .semibold
            )

        titleLabel.font = .preferredFont(
            forTextStyle: .headline
        )
        titleLabel.textColor = .label
        titleLabel.adjustsFontForContentSizeCategory =
            true
        titleLabel.numberOfLines = 1

        subtitleLabel.font = .preferredFont(
            forTextStyle: .caption1
        )
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.adjustsFontForContentSizeCategory =
            true
        subtitleLabel.numberOfLines = 2

        textStackView.axis = .vertical
        textStackView.spacing = 4
        textStackView.addArrangedSubview(titleLabel)
        textStackView.addArrangedSubview(subtitleLabel)
    }

    private func configureLayout() {
        surfaceView.translatesAutoresizingMaskIntoConstraints =
            false
        artworkView.translatesAutoresizingMaskIntoConstraints =
            false
        symbolView.translatesAutoresizingMaskIntoConstraints =
            false
        favoriteView.translatesAutoresizingMaskIntoConstraints =
            false
        textStackView.translatesAutoresizingMaskIntoConstraints =
            false

        addSubview(surfaceView)
        surfaceView.addSubview(artworkView)
        artworkView.addSubview(symbolView)
        surfaceView.addSubview(favoriteView)
        surfaceView.addSubview(textStackView)

        NSLayoutConstraint.activate([
            surfaceView.leadingAnchor.constraint(
                equalTo: leadingAnchor
            ),
            surfaceView.trailingAnchor.constraint(
                equalTo: trailingAnchor
            ),
            surfaceView.topAnchor.constraint(
                equalTo: topAnchor
            ),
            surfaceView.bottomAnchor.constraint(
                equalTo: bottomAnchor
            ),

            artworkView.leadingAnchor.constraint(
                equalTo: surfaceView.leadingAnchor,
                constant: 12
            ),
            artworkView.trailingAnchor.constraint(
                equalTo: surfaceView.trailingAnchor,
                constant: -12
            ),
            artworkView.topAnchor.constraint(
                equalTo: surfaceView.topAnchor,
                constant: 12
            ),
            artworkView.heightAnchor.constraint(
                equalToConstant: 96
            ),

            symbolView.centerXAnchor.constraint(
                equalTo: artworkView.centerXAnchor
            ),
            symbolView.centerYAnchor.constraint(
                equalTo: artworkView.centerYAnchor
            ),
            symbolView.widthAnchor.constraint(
                equalToConstant: 44
            ),
            symbolView.heightAnchor.constraint(
                equalToConstant: 44
            ),

            favoriteView.topAnchor.constraint(
                equalTo: artworkView.topAnchor,
                constant: 10
            ),
            favoriteView.trailingAnchor.constraint(
                equalTo: artworkView.trailingAnchor,
                constant: -10
            ),
            favoriteView.widthAnchor.constraint(
                equalToConstant: 24
            ),
            favoriteView.heightAnchor.constraint(
                equalToConstant: 24
            ),

            textStackView.leadingAnchor.constraint(
                equalTo: surfaceView.leadingAnchor,
                constant: 14
            ),
            textStackView.trailingAnchor.constraint(
                equalTo: surfaceView.trailingAnchor,
                constant: -14
            ),
            textStackView.topAnchor.constraint(
                equalTo: artworkView.bottomAnchor,
                constant: 12
            ),
            textStackView.bottomAnchor.constraint(
                equalTo: surfaceView.bottomAnchor,
                constant: -14
            ),
        ])
    }
}
