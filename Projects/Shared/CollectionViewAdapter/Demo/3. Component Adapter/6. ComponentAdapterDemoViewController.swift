import CollectionViewAdapter
import UIKit

/// Component와 Section DSL, Compositional Layout을 함께 사용하는 예제입니다.
@MainActor
final class ComponentAdapterDemoViewController: UIViewController {
    private let accounts = ComponentDemoAccount.sample
    private let layoutAdapter = CollectionViewLayoutAdapter()
    
    private var isNotificationEnabled = true
    
    private lazy var collectionView: UICollectionView = {
        let configuration =
        UICollectionViewCompositionalLayoutConfiguration()
        configuration.interSectionSpacing = 24
        
        let layout = UICollectionViewCompositionalLayout(
            sectionProvider: layoutAdapter.sectionLayout,
            configuration: configuration
        )
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: layout
        )
        collectionView.backgroundColor = ComponentDemoStyle.background
        collectionView.alwaysBounceVertical = true
        collectionView.contentInset = UIEdgeInsets(
            top: 12,
            left: 0,
            bottom: 32,
            right: 0
        )
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    private lazy var adapter =
    CollectionViewAdapter(
        collectionView: collectionView,
        layoutAdapter: layoutAdapter
    )
    
    /// 화면 상태로부터 현재 Section tree를 만듭니다.
    private var sections: SectionModels {
        SectionModels {
            LazySection(identifier: "accounts") {
                For(of: self.accounts) { account in
                    ComponentDemoRowComponent(
                        identifier: account.id
                    )
                    .title(
                        account.name,
                        subtitle: account.balanceText
                    )
                    .symbol(account.symbolName)
                    .accessory(.button("송금"))
                    .appearance(.connectedCard)
                    .onTouch { [weak self] in
                        self?.showAccount(account)
                    }
                    .onButtonTap { [weak self] in
                        self?.showTransfer(account)
                    }
                }
            }
            .withHeader(
                ComponentDemoTextComponent(
                    identifier: "accounts-header",
                    text: "내 계좌",
                    style: .header
                )
            )
            .withFooter(
                ComponentDemoTextComponent(
                    identifier: "accounts-footer",
                    text: "예금자보호 안내 보기",
                    style: .footer
                )
            )
            .withSectionLayout(
                .verticalList(spacing: 0)
            )
            
            LazySection(identifier: "settings") {
                ComponentDemoRowComponent(
                    identifier: "notification"
                )
                .title(
                    "입출금 알림",
                    subtitle: "계좌 활동을 바로 알려드려요"
                )
                .symbol("bell.fill")
                .accessory(
                    .toggle(
                        isOn: self.isNotificationEnabled
                    )
                )
                .appearance(.standaloneCard)
                .onToggle { [weak self] isOn in
                    self?.updateNotification(isOn: isOn)
                }
            }
            .withSectionLayout(.verticalList())
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        render(animatingDifferences: false)
    }
    
    private func configureView() {
        title = "Component Adapter"
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
            ),
        ])
    }
    
    private func render(
        animatingDifferences: Bool = true
    ) {
        adapter.bind(
            sections,
            animatingDifferences: animatingDifferences
        )
    }
    
    private func updateNotification(isOn: Bool) {
        isNotificationEnabled = isOn
        render(animatingDifferences: false)
    }
    
    private func showAccount(
        _ account: ComponentDemoAccount
    ) {
        showAlert(
            title: account.name,
            message: "현재 잔액은 \(account.balanceText)입니다."
        )
    }
    
    private func showTransfer(
        _ account: ComponentDemoAccount
    ) {
        showAlert(
            title: "송금",
            message: "\(account.name)에서 송금을 시작합니다."
        )
    }
    
    private func showAlert(
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

#Preview {
    UINavigationController(
        rootViewController:
            ComponentAdapterDemoViewController()
    )
}
