//
//  AccountListSupplementaryView.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/28/26.
//

import UIKit

/// Basic 예제의 header와 footer를 표시합니다.
final class AccountListSupplementaryView: UICollectionReusableView {

    enum Kind {
        case header
        case footer
    }

    static let reuseIdentifier = "AccountListSupplementaryView"
    static let headerHeight: CGFloat = 62
    static let footerHeight: CGFloat = 48

    private let headerContentView = UIView()

    private let headerIconView: UIImageView = {
        let configuration = UIImage.SymbolConfiguration(
            pointSize: 18,
            weight: .semibold
        )
        let imageView = UIImageView(
            image: UIImage(
                systemName: "creditcard.fill",
                withConfiguration: configuration
            )
        )

        imageView.tintColor = ComponentDemoStyle.textPrimary
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let headerTitleLabel: UILabel = {
        let label = UILabel()

        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = ComponentDemoStyle.textPrimary
        label.adjustsFontForContentSizeCategory = true
        label.text = "내 계좌"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let headerDescriptionLabel: UILabel = {
        let label = UILabel()

        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = ComponentDemoStyle.textSecondary
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.text = "기본 UICollectionView로 계좌 목록을 표시합니다."
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let footerLabel: UILabel = {
        let label = UILabel()

        label.font = UIFontMetrics(forTextStyle: .caption1)
            .scaledFont(
                for: .systemFont(
                    ofSize: 13,
                    weight: .medium
                )
            )
        label.textColor = ComponentDemoStyle.textSecondary
        label.adjustsFontForContentSizeCategory = true
        label.text = "예금자보호 안내 보기"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        configureLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        footerLabel.text = nil
    }

    func configure(kind: Kind) {
        switch kind {
        case .header:
            headerContentView.isHidden = false
            footerLabel.isHidden = true
            return

        case .footer:
            headerContentView.isHidden = true
            footerLabel.isHidden = false
            footerLabel.text = "예금자보호 안내 보기"
        }
    }

    private func configureLayout() {
        headerContentView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(headerContentView)
        headerContentView.addSubview(headerIconView)
        headerContentView.addSubview(headerTitleLabel)
        headerContentView.addSubview(headerDescriptionLabel)
        addSubview(footerLabel)

        NSLayoutConstraint.activate([
            headerContentView.topAnchor.constraint(
                equalTo: topAnchor
            ),
            headerContentView.leadingAnchor.constraint(
                equalTo: leadingAnchor
            ),
            headerContentView.trailingAnchor.constraint(
                equalTo: trailingAnchor
            ),
            headerContentView.bottomAnchor.constraint(
                equalTo: bottomAnchor
            ),

            headerIconView.topAnchor.constraint(
                equalTo: headerContentView.topAnchor,
                constant: 14
            ),
            headerIconView.leadingAnchor.constraint(
                equalTo: headerContentView.leadingAnchor,
                constant: 20
            ),
            headerIconView.widthAnchor.constraint(
                equalToConstant: 20
            ),
            headerIconView.heightAnchor.constraint(
                equalToConstant: 20
            ),

            headerTitleLabel.leadingAnchor.constraint(
                equalTo: headerIconView.trailingAnchor,
                constant: 8
            ),
            headerTitleLabel.centerYAnchor.constraint(
                equalTo: headerIconView.centerYAnchor
            ),
            headerTitleLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: headerContentView.trailingAnchor,
                constant: -20
            ),

            headerDescriptionLabel.topAnchor.constraint(
                equalTo: headerIconView.bottomAnchor,
                constant: 6
            ),
            headerDescriptionLabel.leadingAnchor.constraint(
                equalTo: headerContentView.leadingAnchor,
                constant: 20
            ),
            headerDescriptionLabel.trailingAnchor.constraint(
                equalTo: headerContentView.trailingAnchor,
                constant: -20
            ),
            headerDescriptionLabel.bottomAnchor.constraint(
                lessThanOrEqualTo: headerContentView.bottomAnchor,
                constant: -5
            ),

            footerLabel.topAnchor.constraint(
                equalTo: topAnchor,
                constant: 14
            ),
            footerLabel.leadingAnchor.constraint(
                equalTo: leadingAnchor,
                constant: 20
            ),
            footerLabel.trailingAnchor.constraint(
                equalTo: trailingAnchor,
                constant: -20
            ),
            footerLabel.bottomAnchor.constraint(
                lessThanOrEqualTo: bottomAnchor,
                constant: -18
            )
        ])

        footerLabel.isHidden = true
    }
}
