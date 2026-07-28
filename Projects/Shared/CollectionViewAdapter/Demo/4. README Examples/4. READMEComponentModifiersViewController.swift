import CollectionViewAdapter
import UIKit

/// Content가 채택한 capability에 필요한 modifier만 합성합니다.
@MainActor
final class READMEComponentModifiersViewController:
    UIViewController {
    private var isSwitchOn = true

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout:
                UICollectionViewFlowLayout()
        )
        collectionView.backgroundColor =
            .systemGroupedBackground
        collectionView.alwaysBounceVertical = true
        collectionView.contentInset = UIEdgeInsets(
            top: 20,
            left: 0,
            bottom: 28,
            right: 0
        )
        collectionView.translatesAutoresizingMaskIntoConstraints =
            false
        return collectionView
    }()

    private lazy var adapter = CollectionViewAdapter(
        collectionView: collectionView
    )

    private var sections: SectionModels {
        SectionModels {
            LazySection(identifier: "modifiers") {
                TouchableDemoComponent(
                    item: .init(kind: .touchable)
                )
                .onTouch {}

                PressableDemoComponent(
                    item: .init(kind: .pressable)
                )
                .pressedEffect(scale: 0.94)

                ContainsSwitchDemoComponent(
                    item: .init(
                        kind: .containsSwitch,
                        isOn: self.isSwitchOn
                    )
                )
                .onToggle { [weak self] isOn in
                    self?.isSwitchOn = isOn
                    self?.render(
                        animatingDifferences: false
                    )
                }
            }
            .withSectionLayout(
                .verticalList(
                    estimatedRowHeight: 164,
                    spacing: 14,
                    contentInsets:
                        NSDirectionalEdgeInsets(
                            top: 0,
                            leading: 20,
                            bottom: 0,
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

        render(animatingDifferences: false)
    }

    private func render(
        animatingDifferences: Bool
    ) {
        adapter.bind(
            sections,
            animatingDifferences: animatingDifferences
        )
    }
}
