import CollectionViewAdapter
import UIKit

private final class ReadmeFinanceSummaryContentView: UIControl, Touchable {
    struct Item: Identifiable, Equatable {
        let id: String
        let title: String
        let amount: String
        let detail: String
        let symbolName: String
        let detailSymbolName: String
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
    private let titleLabel = UILabel()
    private let amountLabel = UILabel()
    private let symbolBackgroundView = UIView()
    private let symbolView = UIImageView()
    private let detailSymbolView = UIImageView()
    private let detailLabel = UILabel()
    private let detailStackView = UIStackView()
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
                ? CGAffineTransform(scaleX: 0.98, y: 0.98)
                : .identity
        }
    }

    private func applyItem() {
        guard let item else {
            titleLabel.text = nil
            amountLabel.text = nil
            detailLabel.text = nil
            symbolView.image = nil
            detailSymbolView.image = nil
            accessibilityLabel = nil
            return
        }

        titleLabel.text = item.title
        amountLabel.text = item.amount
        detailLabel.text = item.detail
        symbolView.image = UIImage(systemName: item.symbolName)
        detailSymbolView.image = UIImage(
            systemName: item.detailSymbolName
        )
        accessibilityLabel =
            "\(item.title), \(item.amount), \(item.detail)"
    }

    private func configureView() {
        backgroundColor = .clear
        isAccessibilityElement = true
        accessibilityTraits = .button

        surfaceView.backgroundColor = .secondarySystemGroupedBackground
        surfaceView.layer.cornerRadius = 20
        surfaceView.layer.cornerCurve = .continuous
        surfaceView.isUserInteractionEnabled = false

        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = .secondaryLabel

        amountLabel.font = .systemFont(ofSize: 27, weight: .bold)
        amountLabel.textColor = .label

        symbolBackgroundView.backgroundColor =
            UIColor.systemBlue.withAlphaComponent(0.12)
        symbolBackgroundView.layer.cornerRadius = 14

        symbolView.tintColor = .systemBlue
        symbolView.contentMode = .scaleAspectFit
        symbolView.preferredSymbolConfiguration =
            UIImage.SymbolConfiguration(
                pointSize: 18,
                weight: .semibold
            )

        detailSymbolView.tintColor = .systemGreen
        detailSymbolView.contentMode = .scaleAspectFit
        detailSymbolView.preferredSymbolConfiguration =
            UIImage.SymbolConfiguration(
                pointSize: 13,
                weight: .bold
            )

        detailLabel.font = .systemFont(ofSize: 14, weight: .medium)
        detailLabel.textColor = .secondaryLabel
        detailLabel.numberOfLines = 1

        detailStackView.axis = .horizontal
        detailStackView.alignment = .center
        detailStackView.spacing = 6
        detailStackView.addArrangedSubview(detailSymbolView)
        detailStackView.addArrangedSubview(detailLabel)
    }

    private func configureLayout() {
        surfaceView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        amountLabel.translatesAutoresizingMaskIntoConstraints = false
        symbolBackgroundView.translatesAutoresizingMaskIntoConstraints =
            false
        symbolView.translatesAutoresizingMaskIntoConstraints = false
        detailStackView.translatesAutoresizingMaskIntoConstraints = false

        configureHierarchy()
        activateSurfaceConstraints()
        activateContentConstraints()
    }

    private func configureHierarchy() {
        addSubview(surfaceView)
        surfaceView.addSubview(titleLabel)
        surfaceView.addSubview(amountLabel)
        surfaceView.addSubview(symbolBackgroundView)
        symbolBackgroundView.addSubview(symbolView)
        surfaceView.addSubview(detailStackView)
    }

    private func activateSurfaceConstraints() {
        NSLayoutConstraint.activate([
            surfaceView.leadingAnchor.constraint(equalTo: leadingAnchor),
            surfaceView.trailingAnchor.constraint(equalTo: trailingAnchor),
            surfaceView.topAnchor.constraint(equalTo: topAnchor),
            surfaceView.bottomAnchor.constraint(equalTo: bottomAnchor),

            titleLabel.leadingAnchor.constraint(
                equalTo: surfaceView.leadingAnchor,
                constant: 20
            ),
            titleLabel.topAnchor.constraint(
                equalTo: surfaceView.topAnchor,
                constant: 18
            ),

            symbolBackgroundView.trailingAnchor.constraint(
                equalTo: surfaceView.trailingAnchor,
                constant: -18
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
            symbolView.heightAnchor.constraint(equalToConstant: 22)
        ])
    }

    private func activateContentConstraints() {
        NSLayoutConstraint.activate([
            amountLabel.leadingAnchor.constraint(
                equalTo: titleLabel.leadingAnchor
            ),
            amountLabel.topAnchor.constraint(
                equalTo: titleLabel.bottomAnchor,
                constant: 8
            ),
            amountLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: symbolBackgroundView.leadingAnchor,
                constant: -12
            ),

            detailStackView.leadingAnchor.constraint(
                equalTo: titleLabel.leadingAnchor
            ),
            detailStackView.trailingAnchor.constraint(
                lessThanOrEqualTo: surfaceView.trailingAnchor,
                constant: -20
            ),
            detailStackView.bottomAnchor.constraint(
                equalTo: surfaceView.bottomAnchor,
                constant: -18
            ),

            detailSymbolView.widthAnchor.constraint(equalToConstant: 16),
            detailSymbolView.heightAnchor.constraint(equalToConstant: 16)
        ])
    }
}

private struct ReadmeFinanceSummaryComponent: Component {
    typealias Item = ReadmeFinanceSummaryContentView.Item

    let item: Item

    var estimatedHeight: CGFloat {
        154
    }

    func createContent() -> ReadmeFinanceSummaryContentView {
        ReadmeFinanceSummaryContentView()
    }

    func render(
        context _: ComponentContext,
        content: ReadmeFinanceSummaryContentView
    ) {
        content.item = item
    }
}

/// 첫 Section은 Horizontal, 두 번째 Section은 Vertical로 구성합니다.
@MainActor
final class ReadmeMixedSectionsViewController:
    UIViewController {
    private let summaries: [ReadmeFinanceSummaryContentView.Item] = [
        .init(
            id: "spending",
            title: "이번 주 소비",
            amount: "184,500원",
            detail: "지난주보다 32,000원 덜 썼어요",
            symbolName: "creditcard.fill",
            detailSymbolName: "arrow.down.right"
        ),
        .init(
            id: "saving",
            title: "이번 달 저축",
            amount: "720,000원",
            detail: "목표까지 280,000원 남았어요",
            symbolName: "banknote.fill",
            detailSymbolName: "flag.fill"
        ),
        .init(
            id: "budget",
            title: "남은 생활비",
            amount: "315,000원",
            detail: "하루 22,500원씩 쓸 수 있어요",
            symbolName: "calendar",
            detailSymbolName: "checkmark.circle.fill"
        )
    ]

    private let accounts = ComponentDemoAccount.sample

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout:
                UICollectionViewFlowLayout()
        )
        collectionView.backgroundColor =
            .systemGroupedBackground
        collectionView.contentInset = UIEdgeInsets(
            top: 8,
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
        collectionView: collectionView,
        interSectionSpacing: 8
    )

    private var sections: SectionModels {
        SectionModels {
            horizontalSection
            verticalSection
        }
    }

    private var horizontalSection: some SectionModelType {
        LazySection(identifier: "horizontal") {
            For(of: self.summaries) { item in
                ReadmeFinanceSummaryComponent(item: item)
            }
        }
        .withHeader(
            ComponentDemoTextComponent(
                item: .init(
                    id: "horizontal-header",
                    text: "금융 요약",
                    style: .header,
                    appearance: .plain,
                    horizontalInset: 0
                )
            )
        )
        .withSectionLayout(
            .horizontalCarousel(
                itemWidth: 0.78,
                estimatedHeight: 154,
                spacing: 12,
                behavior:
                    .continuousGroupLeadingBoundary,
                contentInsets:
                    NSDirectionalEdgeInsets(
                        top: 6,
                        leading: 20,
                        bottom: 20,
                        trailing: 20
                    )
            )
        )
    }

    private var verticalSection: some SectionModelType {
        LazySection(identifier: "vertical") {
            For(of: self.accounts) { account in
                ComponentDemoRowComponent(
                    item: .init(
                        id: account.id,
                        title: account.name,
                        subtitle: account.balanceText,
                        symbolName: account.symbolName,
                        accessory: .chevron,
                        appearance: .standaloneCard
                    )
                )
            }
        }
        .withHeader(
            ComponentDemoTextComponent(
                item: .init(
                    id: "vertical-header",
                    text: "Vertical",
                    style: .header,
                    appearance: .plain
                )
            )
        )
        .withSectionLayout(
            .verticalList(
                spacing: 10,
                contentInsets:
                    NSDirectionalEdgeInsets(
                        top: 0,
                        leading: 0,
                        bottom: 24,
                        trailing: 0
                    )
            )
        )
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
