import CollectionViewAdapter
import UIKit

/// 하나의 Section에 기본 목록을 구성합니다.
@MainActor
final class ReadmeListViewController: UIViewController {
    private let accounts: [ComponentDemoAccount] = [
        .init(
            id: "daily",
            name: "생활비 통장",
            balanceText: "2,450,000원",
            symbolName: "creditcard.fill"
        ),
        .init(
            id: "salary",
            name: "월급 통장",
            balanceText: "5,120,000원",
            symbolName: "banknote.fill"
        ),
        .init(
            id: "travel",
            name: "여행 적금",
            balanceText: "1,800,000원",
            symbolName: "airplane"
        ),
        .init(
            id: "investment",
            name: "투자 계좌",
            balanceText: "3,080,000원",
            symbolName: "chart.line.uptrend.xyaxis"
        )
    ]

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout:
                UICollectionViewFlowLayout()
        )
        collectionView.backgroundColor =
            ComponentDemoStyle.background
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
            LazySection(identifier: "list") {
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
            .withSectionLayout(
                .verticalList(spacing: 10)
            )
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ComponentDemoStyle.background
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
