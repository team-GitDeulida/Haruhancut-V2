import DSKit
import UIKit

final class SettingView: UIView {
    let collectionView:
        UICollectionView = {
            let collectionView =
                UICollectionView(
                    frame: .zero,
                    collectionViewLayout:
                        UICollectionViewFlowLayout()
                )
            collectionView
                .backgroundColor =
                .background
            collectionView
                .alwaysBounceVertical =
                true
            return collectionView
        }()

    let logoutButton: UIButton = {
        HCNextButton(
            title:
                LocalizationKey
                    .profileSettingLogout
                    .localized
        )
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
            collectionView,
            logoutButton,
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
                    equalTo:
                        logoutButton
                            .topAnchor,
                    constant: -12
                ),
            logoutButton.leadingAnchor
                .constraint(
                    equalTo:
                        leadingAnchor,
                    constant: 10
                ),
            logoutButton.trailingAnchor
                .constraint(
                    equalTo:
                        trailingAnchor,
                    constant: -10
                ),
            logoutButton.bottomAnchor
                .constraint(
                    equalTo:
                        safeAreaLayoutGuide
                            .bottomAnchor,
                    constant: -10
                ),
            logoutButton.heightAnchor
                .constraint(
                    equalToConstant: 50
                ),
        ])
    }
}
