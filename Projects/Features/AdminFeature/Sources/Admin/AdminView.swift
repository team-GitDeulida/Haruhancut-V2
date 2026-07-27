import DSKit
import UIKit

final class AdminView:
    UIView
{
    let collectionView:
        UICollectionView = {
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
                .alwaysBounceVertical =
                true
            return collectionView
        }()

    let emptyLabel:
        UILabel = {
            let label = UILabel()
            label.text =
                LocalizationKey
                    .adminEmpty
                    .localized
            label.font =
                .hcFont(
                    .medium,
                    size: 16
                )
            label.textColor = .gray
            label.textAlignment =
                .center
            label.numberOfLines = 0
            label.isHidden = true
            return label
        }()

    let activityIndicator =
        UIActivityIndicatorView(
            style: .medium
        )

    override init(
        frame: CGRect
    ) {
        super.init(frame: frame)
        configureView()
        configureLayout()
    }

    @available(*, unavailable)
    required init?(
        coder: NSCoder
    ) {
        fatalError(
            "init(coder:)는 지원하지 않습니다."
        )
    }

    private func configureView() {
        backgroundColor = .background
        activityIndicator.color =
            .mainWhite

        [
            collectionView,
            emptyLabel,
            activityIndicator,
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints =
                false
            addSubview($0)
        }
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
                    equalTo: leadingAnchor
                ),
            collectionView.trailingAnchor
                .constraint(
                    equalTo: trailingAnchor
                ),
            collectionView.bottomAnchor
                .constraint(
                    equalTo: bottomAnchor
                ),

            emptyLabel.centerXAnchor
                .constraint(
                    equalTo: centerXAnchor
                ),
            emptyLabel.centerYAnchor
                .constraint(
                    equalTo: centerYAnchor
                ),
            emptyLabel.leadingAnchor
                .constraint(
                    greaterThanOrEqualTo:
                        leadingAnchor,
                    constant: 30
                ),

            activityIndicator
                .centerXAnchor
                .constraint(
                    equalTo:
                        centerXAnchor
                ),
            activityIndicator
                .centerYAnchor
                .constraint(
                    equalTo:
                        centerYAnchor
                ),
        ])
    }
}
