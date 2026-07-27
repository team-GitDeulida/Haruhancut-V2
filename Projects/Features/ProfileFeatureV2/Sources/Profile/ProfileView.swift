import DSKit
import UIKit

final class ProfileView: UIView {
    var loadingView: UIView?

    let profileImageView =
        ProfileImageView(
            size: 100,
            iconSize: 60
        )

    let nicknameLabel: HCLabel = {
        HCLabel(type: .main(text: ""))
    }()

    let editButton: UIButton = {
        let button = UIButton(
            type: .system
        )
        button.setImage(
            UIImage(systemName: "pencil"),
            for: .normal
        )
        button.tintColor = .mainWhite
        button.accessibilityLabel =
            "닉네임 수정"
        return button
    }()

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

    private let flexibleSpacer = UIView()

    private lazy var headerStackView:
        UIStackView = {
            let stackView = UIStackView(
                arrangedSubviews: [
                    profileImageView,
                    nicknameLabel,
                    flexibleSpacer,
                    editButton,
                ]
            )
            stackView.axis = .horizontal
            stackView.spacing = 12
            stackView.alignment = .center
            nicknameLabel
                .setContentCompressionResistancePriority(
                    .required,
                    for: .horizontal
                )
            editButton
                .setContentCompressionResistancePriority(
                    .required,
                    for: .horizontal
                )
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
            headerStackView,
            collectionView,
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints =
                false
            addSubview($0)
        }
    }

    private func configureLayout() {
        NSLayoutConstraint.activate([
            headerStackView.topAnchor
                .constraint(
                    equalTo:
                        safeAreaLayoutGuide
                            .topAnchor,
                    constant: 30
                ),
            headerStackView.leadingAnchor
                .constraint(
                    equalTo:
                        safeAreaLayoutGuide
                            .leadingAnchor,
                    constant: 20
                ),
            headerStackView.trailingAnchor
                .constraint(
                    equalTo:
                        safeAreaLayoutGuide
                            .trailingAnchor,
                    constant: -20
                ),

            collectionView.topAnchor
                .constraint(
                    equalTo:
                        headerStackView
                            .bottomAnchor,
                    constant: 50
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
        ])
    }
}
