import CollectionViewAdapter
import UIKit

private final class ReadmeFinanceGridContentView: UIControl, Touchable {
    enum Tone: Equatable {
        case blue
        case green
        case orange
        case purple
        case red

        var color: UIColor {
            switch self {
            case .blue:
                .systemBlue
            case .green:
                .systemGreen
            case .orange:
                .systemOrange
            case .purple:
                .systemPurple
            case .red:
                .systemRed
            }
        }
    }

    struct Item: Identifiable, Equatable {
        let id: String
        let title: String
        let value: String
        let symbolName: String
        let tone: Tone
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
    private let symbolBackgroundView = UIView()
    private let symbolView = UIImageView()
    private let chevronView = UIImageView(
        image: UIImage(systemName: "chevron.right")
    )
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()

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
                ? CGAffineTransform(scaleX: 0.97, y: 0.97)
                : .identity
        }
    }

    private func applyItem() {
        guard let item else {
            titleLabel.text = nil
            valueLabel.text = nil
            symbolView.image = nil
            accessibilityLabel = nil
            return
        }

        titleLabel.text = item.title
        valueLabel.text = item.value
        symbolView.image = UIImage(systemName: item.symbolName)
        symbolView.tintColor = item.tone.color
        symbolBackgroundView.backgroundColor =
            item.tone.color.withAlphaComponent(0.12)
        accessibilityLabel = "\(item.title), \(item.value)"
    }

    private func configureView() {
        backgroundColor = .clear
        isAccessibilityElement = true
        accessibilityTraits = .button

        surfaceView.backgroundColor = .secondarySystemGroupedBackground
        surfaceView.layer.cornerRadius = 20
        surfaceView.layer.cornerCurve = .continuous
        surfaceView.isUserInteractionEnabled = false

        symbolBackgroundView.layer.cornerRadius = 14
        symbolBackgroundView.layer.cornerCurve = .continuous

        symbolView.contentMode = .scaleAspectFit
        symbolView.preferredSymbolConfiguration =
            UIImage.SymbolConfiguration(
                pointSize: 19,
                weight: .semibold
            )

        chevronView.tintColor = .tertiaryLabel
        chevronView.contentMode = .scaleAspectFit
        chevronView.preferredSymbolConfiguration =
            UIImage.SymbolConfiguration(
                pointSize: 12,
                weight: .semibold
            )

        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label

        valueLabel.font = .systemFont(ofSize: 14, weight: .medium)
        valueLabel.textColor = .secondaryLabel
        valueLabel.numberOfLines = 1
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.minimumScaleFactor = 0.85
    }

    private func configureLayout() {
        [
            surfaceView,
            symbolBackgroundView,
            symbolView,
            chevronView,
            titleLabel,
            valueLabel
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        addSubview(surfaceView)
        surfaceView.addSubview(symbolBackgroundView)
        symbolBackgroundView.addSubview(symbolView)
        surfaceView.addSubview(chevronView)
        surfaceView.addSubview(titleLabel)
        surfaceView.addSubview(valueLabel)

        activateSurfaceConstraints()
        activateContentConstraints()
    }

    private func activateSurfaceConstraints() {
        NSLayoutConstraint.activate([
            surfaceView.leadingAnchor.constraint(equalTo: leadingAnchor),
            surfaceView.trailingAnchor.constraint(equalTo: trailingAnchor),
            surfaceView.topAnchor.constraint(equalTo: topAnchor),
            surfaceView.bottomAnchor.constraint(equalTo: bottomAnchor),

            symbolBackgroundView.leadingAnchor.constraint(
                equalTo: surfaceView.leadingAnchor,
                constant: 16
            ),
            symbolBackgroundView.topAnchor.constraint(
                equalTo: surfaceView.topAnchor,
                constant: 16
            ),
            symbolBackgroundView.widthAnchor.constraint(
                equalToConstant: 44
            ),
            symbolBackgroundView.heightAnchor.constraint(
                equalToConstant: 44
            ),

            symbolView.centerXAnchor.constraint(
                equalTo: symbolBackgroundView.centerXAnchor
            ),
            symbolView.centerYAnchor.constraint(
                equalTo: symbolBackgroundView.centerYAnchor
            ),
            symbolView.widthAnchor.constraint(equalToConstant: 22),
            symbolView.heightAnchor.constraint(equalToConstant: 22),

            chevronView.centerYAnchor.constraint(
                equalTo: symbolBackgroundView.centerYAnchor
            ),
            chevronView.trailingAnchor.constraint(
                equalTo: surfaceView.trailingAnchor,
                constant: -16
            ),
            chevronView.widthAnchor.constraint(equalToConstant: 10),
            chevronView.heightAnchor.constraint(equalToConstant: 16)
        ])
    }

    private func activateContentConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(
                equalTo: surfaceView.leadingAnchor,
                constant: 16
            ),
            titleLabel.trailingAnchor.constraint(
                equalTo: surfaceView.trailingAnchor,
                constant: -16
            ),
            titleLabel.topAnchor.constraint(
                equalTo: symbolBackgroundView.bottomAnchor,
                constant: 16
            ),

            valueLabel.leadingAnchor.constraint(
                equalTo: titleLabel.leadingAnchor
            ),
            valueLabel.trailingAnchor.constraint(
                equalTo: titleLabel.trailingAnchor
            ),
            valueLabel.topAnchor.constraint(
                equalTo: titleLabel.bottomAnchor,
                constant: 5
            ),
            valueLabel.bottomAnchor.constraint(
                lessThanOrEqualTo: surfaceView.bottomAnchor,
                constant: -16
            )
        ])
    }
}

private struct ReadmeFinanceGridComponent: Component {
    typealias Item = ReadmeFinanceGridContentView.Item

    let item: Item

    var estimatedHeight: CGFloat {
        150
    }

    func createContent() -> ReadmeFinanceGridContentView {
        ReadmeFinanceGridContentView()
    }

    func render(
        context _: ComponentContext,
        content: ReadmeFinanceGridContentView
    ) {
        content.item = item
    }
}

/// 하나의 Section에 카드를 2열 Grid로 배치합니다.
@MainActor
final class ReadmeGridViewController:
    UIViewController {
    private let items: [ReadmeFinanceGridContentView.Item] = [
        .init(
            id: "spending",
            title: "이번 달 소비",
            value: "842,300원",
            symbolName: "creditcard.fill",
            tone: .blue
        ),
        .init(
            id: "credit-score",
            title: "신용점수",
            value: "상위 18%",
            symbolName: "gauge.with.dots.needle.67percent",
            tone: .purple
        ),
        .init(
            id: "insurance",
            title: "내 보험",
            value: "보장 5개",
            symbolName: "shield.fill",
            tone: .green
        ),
        .init(
            id: "loan",
            title: "대출 한도",
            value: "바로 확인",
            symbolName: "banknote.fill",
            tone: .orange
        ),
        .init(
            id: "investment",
            title: "투자",
            value: "수익률 +8.4%",
            symbolName: "chart.line.uptrend.xyaxis",
            tone: .red
        ),
        .init(
            id: "benefit",
            title: "받을 혜택",
            value: "3개 있어요",
            symbolName: "gift.fill",
            tone: .blue
        )
    ]

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout:
                UICollectionViewFlowLayout()
        )
        collectionView.backgroundColor =
            .systemGroupedBackground
        collectionView.contentInset = UIEdgeInsets(
            top: 18,
            left: 0,
            bottom: 32,
            right: 0
        )
        collectionView.alwaysBounceVertical = true
        collectionView.translatesAutoresizingMaskIntoConstraints =
            false
        return collectionView
    }()

    private lazy var adapter = CollectionViewAdapter(
        collectionView: collectionView
    )

    private var sections: SectionModels {
        SectionModels {
            LazySection(identifier: "grid") {
                For(of: self.items) { item in
                    ReadmeFinanceGridComponent(item: item)
                }
            }
            .withSectionLayout(
                .grid(
                    columns: 2,
                    estimatedRowHeight: 150,
                    interItemSpacing: 12,
                    lineSpacing: 12,
                    contentInsets:
                        NSDirectionalEdgeInsets(
                            top: 0,
                            leading: 20,
                            bottom: 24,
                            trailing: 20
                        )
                )
            )
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),
            collectionView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            ),
            collectionView.topAnchor.constraint(
                equalTo: view.topAnchor
            ),
            collectionView.bottomAnchor.constraint(
                equalTo: view.bottomAnchor
            )
        ])

        adapter.bind(
            sections,
            animatingDifferences: false
        )
    }
}
