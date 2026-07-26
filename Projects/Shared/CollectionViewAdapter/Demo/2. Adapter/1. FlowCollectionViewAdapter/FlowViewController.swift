import CollectionViewAdapter
import UIKit

enum DemoSection: Hashable, CaseIterable {
    case essentials
    case events

    var title: String {
        switch self {
        case .essentials:
            return "Adapter Essentials"
        case .events:
            return "Delegate Events"
        }
    }
}

struct DemoItem: Hashable {
    let id: UUID
    let title: String
    let subtitle: String
    let symbolName: String
    let tintColor: UIColor

    init(
        id: UUID = UUID(),
        title: String,
        subtitle: String,
        symbolName: String,
        tintColor: UIColor
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.symbolName = symbolName
        self.tintColor = tintColor
    }

    static func == (lhs: DemoItem, rhs: DemoItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

final class FlowViewController: UIViewController {
    private let sectionInsets = UIEdgeInsets(top: 8, left: 20, bottom: 28, right: 20)
    private let itemSpacing: CGFloat = 12

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = itemSpacing
        layout.minimumInteritemSpacing = itemSpacing

        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: layout
        )
        collectionView.backgroundColor = .systemBackground
        collectionView.alwaysBounceVertical = true
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(
            DemoCollectionViewCell.self,
            forCellWithReuseIdentifier: DemoCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            DemoSectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: DemoSectionHeaderView.reuseIdentifier
        )
        return collectionView
    }()

    private lazy var adapter = makeAdapter()
    private var sections = FlowViewController.initialSections

    override func viewDidLoad() {
        super.viewDidLoad()
        configureHierarchy()
        configureAdapterCallbacks()
        applySections(animatingDifferences: false)
    }

    private func configureHierarchy() {
        view.backgroundColor = .systemBackground
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func makeAdapter() -> FlowCollectionViewAdapter<DemoSection, DemoItem> {
        let adapter = FlowCollectionViewAdapter<DemoSection, DemoItem>(
            collectionView: collectionView
        ) { collectionView, indexPath, item in
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: DemoCollectionViewCell.reuseIdentifier,
                for: indexPath
            ) as? DemoCollectionViewCell else {
                return nil
            }

            cell.configure(with: item)
            return cell
        }

        adapter.supplementaryViewProvider = { [weak adapter] collectionView, kind, indexPath in
            guard
                kind == UICollectionView.elementKindSectionHeader,
                let section = adapter?.snapshot().sectionIdentifiers[indexPath.section],
                let header = collectionView.dequeueReusableSupplementaryView(
                    ofKind: kind,
                    withReuseIdentifier: DemoSectionHeaderView.reuseIdentifier,
                    for: indexPath
                ) as? DemoSectionHeaderView
            else {
                return nil
            }

            header.configure(title: section.title)
            return header
        }

        return adapter
    }

    private func configureAdapterCallbacks() {
        adapter.didSelectItem = { [weak self] collectionView, indexPath, item in
            collectionView.deselectItem(at: indexPath, animated: true)
            self?.presentSelection(of: item)
        }

        adapter.sizeForItem = { [weak self] collectionView, _, _, _ in
            guard let self else { return .zero }

            let availableWidth = collectionView.bounds.width
                - self.sectionInsets.left
                - self.sectionInsets.right
            let minimumItemWidth: CGFloat = 150
            let columnCount = max(
                1,
                Int((availableWidth + self.itemSpacing) / (minimumItemWidth + self.itemSpacing))
            )
            let totalSpacing = CGFloat(columnCount - 1) * self.itemSpacing
            let itemWidth = floor((availableWidth - totalSpacing) / CGFloat(columnCount))
            return CGSize(width: itemWidth, height: 172)
        }

        adapter.insetForSection = { [weak self] _, _, _, _ in
            self?.sectionInsets ?? .zero
        }
        adapter.minimumLineSpacing = { [weak self] _, _, _, _ in
            self?.itemSpacing ?? 0
        }
        adapter.minimumInteritemSpacing = { [weak self] _, _, _, _ in
            self?.itemSpacing ?? 0
        }
        adapter.referenceSizeForHeader = { _, _, _, _ in
            CGSize(width: 1, height: 52)
        }
    }

    private func applySections(animatingDifferences: Bool = true) {
        adapter.apply(
            sections: DemoSection.allCases.compactMap { section in
                guard let items = sections[section] else { return nil }
                return CollectionViewSection(id: section, items: items)
            },
            animatingDifferences: animatingDifferences
        )
    }

    func appendDemoItem() {
        let count = (sections[.events]?.count ?? 0) + 1
        let newItem = DemoItem(
            title: "Snapshot Update \(count)",
            subtitle: "Animated diff without reloadData",
            symbolName: "sparkles",
            tintColor: .systemYellow
        )
        sections[.events, default: []].append(newItem)
        applySections()
    }

    private func presentSelection(of item: DemoItem) {
        let alert = UIAlertController(
            title: item.title,
            message: "didSelectItem callback was forwarded by the adapter.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private static let initialSections: [DemoSection: [DemoItem]] = [
        .essentials: [
            DemoItem(
                title: "Diffable Data Source",
                subtitle: "Type-safe sections and items",
                symbolName: "square.stack.3d.up.fill",
                tintColor: .systemYellow
            ),
            DemoItem(
                title: "Cell Provider",
                subtitle: "Cell creation in one closure",
                symbolName: "rectangle.grid.2x2.fill",
                tintColor: .systemOrange
            ),
            DemoItem(
                title: "UIKit Only",
                subtitle: "No Rx or third-party dependency",
                symbolName: "shippingbox.fill",
                tintColor: .systemBlue
            )
        ],
        .events: [
            DemoItem(
                title: "Selection",
                subtitle: "Tap to test didSelectItem",
                symbolName: "hand.tap.fill",
                tintColor: .systemPink
            ),
            DemoItem(
                title: "Flow Layout",
                subtitle: "Size and spacing callbacks",
                symbolName: "arrow.left.and.right.square.fill",
                tintColor: .systemGreen
            )
        ]
    ]
}
