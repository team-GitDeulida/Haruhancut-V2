import CollectionViewAdapter
import SwiftUI
import UIKit

/// SwiftUI View로 그린 셀(`HostingComponent`)을 보여주는 예제입니다.
///
/// 설정 행은 설명 길이에 따라 높이가 달라지고, 사진 카드는 2열 grid에서
/// 고정 비율로 그립니다. 셀을 누르면 Item이 바뀌어 바뀐 셀만 다시 그립니다.
@MainActor
final class HostingCellDemoViewController: UIViewController {
    private var rows = HostingCellDemoRow.samples
    private var photos = (1...12).map {
        HostingCellDemoPhoto(id: $0, isFavorite: false)
    }

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: UICollectionViewFlowLayout()
        )
        collectionView.backgroundColor = .systemGroupedBackground
        collectionView.alwaysBounceVertical = true
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()

    private lazy var adapter = CollectionViewAdapter(
        collectionView: collectionView,
        interSectionSpacing: 12
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        render()
    }

    private func configureView() {
        title = "SwiftUI Cells"
        view.backgroundColor = .systemGroupedBackground
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func render() {
        adapter.bind {
            LazySection(
                id: "rows",
                layout: .list(
                    spacing: 8,
                    contentInsets: NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
                )
            ) {
                For(self.rows) { row in
                    HostingComponent(item: row, estimatedHeight: 72) { row in
                        HostingCellDemoRowView(row: row)
                    }
                    .pressedEffect()
                    .onTouch { [weak self] in
                        self?.toggleRow(id: row.id)
                    }
                }
            } header: {
                Self.header(
                    id: "rows-header",
                    title: "SwiftUI 행",
                    caption: "설명 길이에 따라 셀 높이가 달라집니다."
                )
            }
            .pinnedHeader()

            LazySection(
                id: "photos",
                layout: .grid(
                    columns: 2,
                    estimatedRowHeight: 140,
                    interItemSpacing: 12,
                    lineSpacing: 12,
                    contentInsets: NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 24, trailing: 16)
                )
            ) {
                For(self.photos) { photo in
                    HostingComponent(item: photo, estimatedHeight: 140) { photo in
                        HostingCellDemoPhotoView(photo: photo)
                    }
                    .pressedEffect()
                    .onTouch { [weak self] in
                        self?.toggleFavorite(id: photo.id)
                    }
                }
            } header: {
                Self.header(
                    id: "photos-header",
                    title: "사진 Grid",
                    caption: "이미지는 고정 비율로 그려 높이가 바뀌지 않습니다."
                )
            }
        }
    }

    private static func header(
        id: String,
        title: String,
        caption: String
    ) -> some Component {
        HostingComponent(
            item: HostingCellDemoHeader(id: id, title: title, caption: caption)
        ) { header in
            VStack(alignment: .leading, spacing: 2) {
                Text(header.title)
                    .font(.headline)
                Text(header.caption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(uiColor: .systemGroupedBackground))
        }
    }

    private func toggleRow(id: String) {
        guard let index = rows.firstIndex(where: { $0.id == id }) else {
            return
        }
        rows[index].isOn.toggle()
        render()
    }

    private func toggleFavorite(id: Int) {
        guard let index = photos.firstIndex(where: { $0.id == id }) else {
            return
        }
        photos[index].isFavorite.toggle()
        render()
    }
}

private struct HostingCellDemoRowView: View {
    let row: HostingCellDemoRow

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: row.symbolName)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(row.title)
                    .font(.headline)
                Text(row.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Image(systemName: row.isOn ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(row.isOn ? Color.accentColor : Color.secondary)
        }
        .padding(16)
        .background(
            Color(uiColor: .secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 14)
        )
    }
}

private struct HostingCellDemoPhotoView: View {
    let photo: HostingCellDemoPhoto

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Color.secondary.opacity(0.15)
                .aspectRatio(3 / 2, contentMode: .fit)
                .overlay {
                    AsyncImage(url: photo.imageURL) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        ProgressView()
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(alignment: .topTrailing) {
                    Image(systemName: photo.isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(photo.isFavorite ? .pink : .white)
                        .padding(8)
                }

            Text("사진 \(photo.id)")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    UINavigationController(
        rootViewController: HostingCellDemoViewController()
    )
}
