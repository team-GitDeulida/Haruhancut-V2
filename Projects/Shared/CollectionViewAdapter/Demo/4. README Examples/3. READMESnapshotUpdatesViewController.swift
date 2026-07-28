import CollectionViewAdapter
import UIKit

/// 같은 ID의 내용 변경과 Item 순서 변경을 새 snapshot으로 반영합니다.
@MainActor
final class READMESnapshotUpdatesViewController:
    UIViewController {
    private var updateCount = 1
    private var accounts = ComponentDemoAccount.sample

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout:
                UICollectionViewFlowLayout()
        )
        collectionView.backgroundColor =
            ComponentDemoStyle.background
        collectionView.alwaysBounceVertical = true
        collectionView.contentInset = UIEdgeInsets(
            top: 18,
            left: 0,
            bottom: 32,
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
            LazySection(identifier: "snapshot") {
                ComponentDemoRowComponent(
                    item: .init(
                        id: "apply-snapshot",
                        title:
                            "Snapshot \(self.updateCount)",
                        subtitle:
                            "같은 ID로 순서와 값을 갱신합니다",
                        symbolName:
                            "arrow.triangle.2.circlepath",
                        accessory: .button("적용"),
                        appearance: .standaloneCard
                    )
                )
                .onButtonTap { [weak self] in
                    self?.applyNextSnapshot()
                }

                For(of: self.accounts) { account in
                    ComponentDemoRowComponent(
                        item: .init(
                            id: account.id,
                            title: account.name,
                            subtitle: account.balanceText,
                            symbolName:
                                account.symbolName,
                            accessory: .chevron,
                            appearance:
                                .standaloneCard
                        )
                    )
                }
            }
            .withHeader(
                ComponentDemoTextComponent(
                    item: .init(
                        id: "snapshot-header",
                        text: "Diffable 상태 갱신",
                        style: .header,
                        appearance: .standalone
                    )
                )
            )
            .withFooter(
                ComponentDemoTextComponent(
                    item: .init(
                        id: "snapshot-footer",
                        text:
                            "Adapter가 insert, move, delete와 content 변경을 계산합니다.",
                        style: .footer,
                        appearance: .standalone
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
                            bottom: 0,
                            trailing: 0
                        )
                )
            )
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor =
            ComponentDemoStyle.background
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

    private func applyNextSnapshot() {
        updateCount += 1

        if updateCount.isMultiple(of: 2) {
            accounts = [
                .init(
                    id: "travel",
                    name: "여행 적금",
                    balanceText: "1,950,000원",
                    symbolName: "airplane"
                ),
                .init(
                    id: "daily",
                    name: "생활비 통장",
                    balanceText: "2,310,000원",
                    symbolName: "creditcard.fill"
                ),
                .init(
                    id: "investment",
                    name: "투자 계좌",
                    balanceText: "3,080,000원",
                    symbolName: "chart.line.uptrend.xyaxis"
                )
            ]
        } else {
            accounts = ComponentDemoAccount.sample
        }

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
