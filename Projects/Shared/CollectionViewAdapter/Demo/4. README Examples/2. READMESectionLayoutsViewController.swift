import CollectionViewAdapter
import UIKit

/// 서로 다른 Compositional Layout 전략을 한 Collection View에 조합합니다.
@MainActor
final class READMESectionLayoutsViewController:
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

    private let topics: [GridDemoContentView.Item] = [
        .init(
            id: "meal",
            title: "한 끼",
            subtitle: "기억하고 싶은 오늘의 맛",
            symbolName: "fork.knife",
            isFavorite: true
        ),
        .init(
            id: "nature",
            title: "자연",
            subtitle: "계절이 남긴 색깔",
            symbolName: "leaf.fill",
            isFavorite: false
        ),
        .init(
            id: "night",
            title: "밤",
            subtitle: "하루를 마무리한 장면",
            symbolName: "moon.stars.fill",
            isFavorite: false
        ),
        .init(
            id: "people",
            title: "사람",
            subtitle: "함께여서 좋았던 순간",
            symbolName: "person.2.fill",
            isFavorite: true
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
        collectionView.alwaysBounceVertical = true
        collectionView.contentInset = UIEdgeInsets(
            top: 8,
            left: 0,
            bottom: 32,
            right: 0
        )
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
            LazySection(identifier: "featured") {
                For(of: self.featured) { item in
                    GridDemoComponent(item: item)
                }
            }
            .withHeader(
                ComponentDemoTextComponent(
                    item: .init(
                        id: "featured-header",
                        text: "가로 Carousel",
                        style: .header,
                        appearance: .standalone,
                        horizontalInset: 0
                    )
                )
            )
            .withSectionLayout(
                .horizontalCarousel(
                    itemWidth: 0.68,
                    estimatedHeight: 178,
                    spacing: 12,
                    behavior:
                        .continuousGroupLeadingBoundary,
                    contentInsets:
                        NSDirectionalEdgeInsets(
                            top: 6,
                            leading: 20,
                            bottom: 18,
                            trailing: 20
                        )
                )
            )

            LazySection(identifier: "topics") {
                For(of: self.topics) { item in
                    GridDemoComponent(item: item)
                }
            }
            .withHeader(
                ComponentDemoTextComponent(
                    item: .init(
                        id: "topics-header",
                        text: "2열 Grid",
                        style: .header,
                        appearance: .standalone,
                        horizontalInset: 0
                    )
                )
            )
            .withSectionLayout(
                .grid(
                    columns: 2,
                    estimatedRowHeight: 178,
                    interItemSpacing: 12,
                    lineSpacing: 12,
                    contentInsets:
                        NSDirectionalEdgeInsets(
                            top: 6,
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
