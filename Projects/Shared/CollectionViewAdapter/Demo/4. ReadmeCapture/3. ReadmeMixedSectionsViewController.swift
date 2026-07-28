import CollectionViewAdapter
import UIKit

/// 첫 Section은 Horizontal, 두 번째 Section은 Vertical로 구성합니다.
@MainActor
final class ReadmeMixedSectionsViewController:
    UIViewController {
    private let featured: [GridDemoContentView.Item] = [
        .init(
            id: "morning",
            title: "아침",
            subtitle: "하루를 시작한 첫 장면",
            symbolName: "sun.max.fill",
            isFavorite: true
        ),
        .init(
            id: "coffee",
            title: "커피",
            subtitle: "잠깐 쉬어간 순간",
            symbolName: "cup.and.saucer.fill",
            isFavorite: false
        ),
        .init(
            id: "walk",
            title: "산책",
            subtitle: "걷다가 발견한 풍경",
            symbolName: "figure.walk",
            isFavorite: false
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
            For(of: self.featured) { item in
                GridDemoComponent(item: item)
            }
        }
        .withHeader(
            ComponentDemoTextComponent(
                item: .init(
                    id: "horizontal-header",
                    text: "Horizontal",
                    style: .header,
                    appearance: .plain,
                    horizontalInset: 0
                )
            )
        )
        .withSectionLayout(
            .horizontalCarousel(
                itemWidth: 0.72,
                estimatedHeight: 178,
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
