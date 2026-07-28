import CollectionViewAdapter
import UIKit

/// README 빠른 시작 코드와 같은 Section DSL 구성을 실행합니다.
@MainActor
final class READMEQuickStartViewController:
    UIViewController {
    private let accounts = ComponentDemoAccount.sample

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
        collectionView: collectionView,
        interSectionSpacing: 22
    )

    private var sections: SectionModels {
        SectionModels {
            LazySection(identifier: "accounts") {
                For(of: self.accounts) { account in
                    ComponentDemoRowComponent(
                        item: .init(
                            id: account.id,
                            title: account.name,
                            subtitle: account.balanceText,
                            symbolName:
                                account.symbolName,
                            accessory: .button("송금"),
                            appearance:
                                .connectedCard
                        )
                    )
                    .onTouch { [weak self] in
                        self?.show(
                            title: account.name,
                            message:
                                account.balanceText
                        )
                    }
                    .onButtonTap { [weak self] in
                        self?.show(
                            title: "송금",
                            message:
                                "\(account.name)에서 송금합니다."
                        )
                    }
                }
            }
            .withHeader(
                ComponentDemoTextComponent(
                    item: .init(
                        id: "accounts-header",
                        text: "오늘의 계좌",
                        style: .header
                    )
                )
            )
            .withFooter(
                ComponentDemoTextComponent(
                    item: .init(
                        id: "accounts-footer",
                        text:
                            "Section, Header, Footer가 하나의 snapshot으로 관리됩니다.",
                        style: .footer
                    )
                )
            )
            .withSectionLayout(
                .verticalList(spacing: 0)
            )
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        adapter.bind(
            sections,
            animatingDifferences: false
        )
    }

    private func configureView() {
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
    }

    private func show(
        title: String,
        message: String
    ) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(
            UIAlertAction(
                title: "확인",
                style: .default
            )
        )
        present(alert, animated: true)
    }
}
