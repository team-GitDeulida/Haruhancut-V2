import CollectionViewAdapter
import UIKit

/// 2열 self-sizing Grid와 Item 상태 갱신을 보여주는 예제입니다.
@MainActor
final class GridDemoViewController: UIViewController {
    private var items: [GridDemoContentView.Item] = [
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
        ),
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
            isFavorite: false
        ),
        .init(
            id: "favorite",
            title: "소중한 것",
            subtitle: "오래 간직하고 싶은 기록",
            symbolName: "heart.fill",
            isFavorite: true
        ),
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
        collectionView.translatesAutoresizingMaskIntoConstraints =
            false
        return collectionView
    }()

    private lazy var adapter = CollectionViewAdapter(
        collectionView: collectionView
    )

    private var sections: SectionModels {
        SectionModels {
            LazySection(identifier: "photo-topics") {
                For(of: self.items) { item in
                    GridDemoComponent(item: item)
                        .onTouch { [weak self] in
                            self?.toggleFavorite(
                                id: item.id
                            )
                        }
                }
            }
            .withSectionLayout(
                CollectionSectionLayout.grid(
                    columns: 2,
                    estimatedRowHeight: 178,
                    interItemSpacing: 12,
                    lineSpacing: 12,
                    contentInsets:
                        NSDirectionalEdgeInsets(
                            top: 16,
                            leading: 10,
                            bottom: 24,
                            trailing: 10
                        )
                )
            )
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        render(animatingDifferences: false)
    }

    private func configureView() {
        title = "Grid Layout"
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
            ),
        ])
    }

    /// 선택한 카드의 상태를 갱신해 Diffable reconfigure를 보여줍니다.
    private func toggleFavorite(id: String) {
        guard
            let index = items.firstIndex(
                where: { $0.id == id }
            )
        else {
            return
        }

        items[index].isFavorite.toggle()
        render()
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
