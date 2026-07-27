import DSKit
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

    private let textLabel: UILabel = {
        let label = HCLabel(
            type: .main(
                text:
                    LocalizationKey
                        .memberFamilyCount
                        .localized
            )
        )
        label.font =
            .hcFont(
                .bold,
                size: 22.scaled
            )
        return label
    }()

    let peopleLabel: UILabel = {
        let label = HCLabel(
            type: .main(
                text: String(
                    format:
                        LocalizationKey
                            .memberFamilyCountValue
                            .localized,
                    0
                )
            )
        )
        label.font =
            .hcFont(
                .bold,
                size: 22.scaled
            )
        label.textColor = .hcColor
        return label
    }()

    private lazy var titleStack:
        UIStackView = {
            let stackView =
                UIStackView(
                    arrangedSubviews: [
                        textLabel,
                        peopleLabel,
                    ]
                )
            stackView.axis = .horizontal
            stackView.spacing = 5
            stackView.alignment = .center
            return stackView
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

        [
            titleStack,
            collectionView,
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints =
                false
            addSubview($0)
        }
    }

    private func configureLayout() {
        NSLayoutConstraint.activate([
            titleStack.topAnchor.constraint(
                equalTo:
                    safeAreaLayoutGuide
                        .topAnchor,
                constant: 40
            ),
            titleStack.leadingAnchor.constraint(
                equalTo:
                    safeAreaLayoutGuide
                        .leadingAnchor,
                constant: 20
            ),

            collectionView.topAnchor
                .constraint(
                    equalTo:
                        titleStack
                            .bottomAnchor,
                    constant: 20
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
