import CollectionViewAdapter
import UIKit

/// 하나의 Section에 카드를 Vertical 목록으로 배치합니다.
@MainActor
final class ReadmeVerticalViewController:
    UIViewController {
    private let items: [GridDemoContentView.Item] = [
        .init(
            id: "morning",
            title: "아침",
            subtitle: "하루를 시작한 첫 장면",
            symbolName: "sun.max.fill",
            isFavorite: true
        ),
        .init(
            id: "meal",
            title: "한 끼",
            subtitle: "기억하고 싶은 오늘의 맛",
            symbolName: "fork.knife",
            isFavorite: false
        ),
        .init(
            id: "walk",
            title: "산책",
            subtitle: "걷다가 발견한 풍경",
            symbolName: "figure.walk",
            isFavorite: true
        ),
        .init(
            id: "night",
            title: "밤",
            subtitle: "하루를 마무리한 장면",
            symbolName: "moon.stars.fill",
            isFavorite: false
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
            LazySection(identifier: "vertical") {
                For(of: self.items) { item in
                    GridDemoComponent(item: item)
                }
            }
            .withSectionLayout(
                .verticalList(
                    spacing: 12,
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
