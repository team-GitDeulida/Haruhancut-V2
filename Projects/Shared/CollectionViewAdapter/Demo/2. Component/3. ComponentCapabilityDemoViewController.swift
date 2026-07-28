import CollectionViewAdapter
import UIKit

/// 하나의 Component capability와 대응 modifier를 독립적으로 보여줍니다.
@MainActor
final class ComponentCapabilityDemoViewController:
    UIViewController
{
    private let kind: ComponentCapabilityDemoKind

    private var interactionCount = 0
    private var isSwitchOn = true

    private let sectionTitleLabel = UILabel()
    private let summaryLabel = UILabel()
    private let resultTitleLabel = UILabel()
    private let resultLabel = UILabel()
    private let resultView = UIView()
    private let headerStackView = UIStackView()
    private let resultStackView = UIStackView()
    private let rootStackView = UIStackView()

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: UICollectionViewFlowLayout()
        )
        collectionView.backgroundColor = .clear
        collectionView.isScrollEnabled = false
        return collectionView
    }()

    private lazy var adapter = CollectionViewAdapter(
        collectionView: collectionView
    )

    private var sections: SectionModels {
        SectionModels {
            LazySection(identifier: kind.rawValue) {
                self.makeDemoComponent()
            }
            .withSectionLayout(
                .verticalList(
                    estimatedRowHeight: 164
                )
            )
        }
    }

    init(kind: ComponentCapabilityDemoKind) {
        self.kind = kind
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:)는 지원하지 않습니다.")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        configureLayout()
        render(animatingDifferences: false)
    }

    private func configureView() {
        title = kind.title
        view.backgroundColor = .systemGroupedBackground

        sectionTitleLabel.text = "COMPONENT CAPABILITY"
        sectionTitleLabel.font = .systemFont(
            ofSize: 12,
            weight: .bold
        )
        sectionTitleLabel.textColor = kind.accentColor

        summaryLabel.text = kind.summary
        summaryLabel.font = .preferredFont(
            forTextStyle: .title3
        )
        summaryLabel.textColor = .label
        summaryLabel.numberOfLines = 0
        summaryLabel.adjustsFontForContentSizeCategory = true

        resultTitleLabel.text = "실행 결과"
        resultTitleLabel.font = .preferredFont(
            forTextStyle: .caption1
        )
        resultTitleLabel.textColor = .secondaryLabel

        resultLabel.text = kind.initialResult
        resultLabel.font = .preferredFont(
            forTextStyle: .body
        )
        resultLabel.textColor = .label
        resultLabel.numberOfLines = 0
        resultLabel.adjustsFontForContentSizeCategory = true

        resultView.backgroundColor =
            kind.accentColor.withAlphaComponent(0.1)
        resultView.layer.cornerRadius = 18
        resultView.layer.cornerCurve = .continuous

        headerStackView.axis = .vertical
        headerStackView.spacing = 8
        headerStackView.addArrangedSubview(sectionTitleLabel)
        headerStackView.addArrangedSubview(summaryLabel)

        resultStackView.axis = .vertical
        resultStackView.spacing = 5
        resultStackView.addArrangedSubview(resultTitleLabel)
        resultStackView.addArrangedSubview(resultLabel)

        rootStackView.axis = .vertical
        rootStackView.spacing = 22
        rootStackView.addArrangedSubview(headerStackView)
        rootStackView.addArrangedSubview(collectionView)
        rootStackView.addArrangedSubview(resultView)

        resultView.addSubview(resultStackView)
        view.addSubview(rootStackView)
    }

    private func configureLayout() {
        rootStackView.translatesAutoresizingMaskIntoConstraints = false
        resultStackView.translatesAutoresizingMaskIntoConstraints =
            false

        collectionView.setContentHuggingPriority(
            .defaultLow,
            for: .vertical
        )

        NSLayoutConstraint.activate([
            rootStackView.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                constant: 20
            ),
            rootStackView.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                constant: -20
            ),
            rootStackView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: 24
            ),
            rootStackView.bottomAnchor.constraint(
                lessThanOrEqualTo:
                    view.safeAreaLayoutGuide.bottomAnchor,
                constant: -24
            ),

            collectionView.heightAnchor.constraint(
                equalToConstant: 180
            ),

            resultStackView.leadingAnchor.constraint(
                equalTo: resultView.leadingAnchor,
                constant: 16
            ),
            resultStackView.trailingAnchor.constraint(
                equalTo: resultView.trailingAnchor,
                constant: -16
            ),
            resultStackView.topAnchor.constraint(
                equalTo: resultView.topAnchor,
                constant: 14
            ),
            resultStackView.bottomAnchor.constraint(
                equalTo: resultView.bottomAnchor,
                constant: -14
            ),
        ])
    }

    private func makeDemoComponent() -> AnyComponent {
        let item = ComponentCapabilityDemoItem(
            kind: kind,
            isOn: isSwitchOn
        )

        switch kind {
        case .touchable:
            return AnyComponent(
                TouchableDemoComponent(item: item)
                    .onTouch { [weak self] in
                        self?.didTouchCard()
                    }
            )

        case .pressable:
            return AnyComponent(
                PressableDemoComponent(item: item)
                    .pressedEffect(scale: 0.94)
            )

        case .containsButton:
            return AnyComponent(
                ContainsButtonDemoComponent(item: item)
                    .onButtonTap { [weak self] in
                        self?.didTapInnerButton()
                    }
            )

        case .containsSwitch:
            return AnyComponent(
                ContainsSwitchDemoComponent(item: item)
                    .onToggle { [weak self] isOn in
                        self?.didToggleSwitch(isOn: isOn)
                    }
            )
        }
    }

    private func didTouchCard() {
        interactionCount += 1
        updateResult(
            "카드 전체 탭 이벤트를 \(interactionCount)번 받았습니다."
        )
    }

    private func didTapInnerButton() {
        interactionCount += 1
        updateResult(
            "내부 버튼 이벤트를 \(interactionCount)번 받았습니다."
        )
    }

    private func didToggleSwitch(isOn: Bool) {
        isSwitchOn = isOn
        updateResult(
            isOn
                ? "알림이 켜졌습니다."
                : "알림이 꺼졌습니다."
        )
        render(animatingDifferences: false)
    }

    private func updateResult(_ text: String) {
        resultLabel.text = text
        UIView.transition(
            with: resultLabel,
            duration: 0.18,
            options: .transitionCrossDissolve
        ) {}
    }

    private func render(
        animatingDifferences: Bool = true
    ) {
        adapter.bind(
            sections,
            animatingDifferences: animatingDifferences
        )
    }
}
