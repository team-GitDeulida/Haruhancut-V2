import UIKit

final class MemberView: UIView {
    let collectionView: UICollectionView = {
        let collectionView =
            UICollectionView(
                frame: .zero,
                collectionViewLayout:
                    UICollectionViewFlowLayout()
            )
        collectionView.backgroundColor =
            .clear
        collectionView
            .showsVerticalScrollIndicator =
            false
        collectionView
            .alwaysBounceVertical = true
        collectionView
            .isPrefetchingEnabled = true
        return collectionView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
        configureLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError(
            "init(coder:)는 지원하지 않습니다."
        )
    }

    private func configureView() {
        backgroundColor = .background

        collectionView
            .translatesAutoresizingMaskIntoConstraints =
            false
        addSubview(collectionView)
    }

    private func configureLayout() {
        NSLayoutConstraint.activate([
            collectionView.topAnchor
                .constraint(
                    equalTo:
                        safeAreaLayoutGuide
                            .topAnchor
                ),
            collectionView.leadingAnchor
                .constraint(
                    equalTo:
                        leadingAnchor,
                    constant: 20
                ),
            collectionView.trailingAnchor
                .constraint(
                    equalTo:
                        trailingAnchor,
                    constant: -20
                ),
            collectionView.bottomAnchor
                .constraint(
                    equalTo:
                        safeAreaLayoutGuide
                            .bottomAnchor
                ),
        ])
    }
}
