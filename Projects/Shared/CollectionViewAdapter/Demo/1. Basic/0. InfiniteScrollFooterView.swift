//
//  InfiniteScrollFooterView.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/28/26.
//

import UIKit

/// 스크롤 기반 페이지 요청의 진행 상태를 표시하는 footer입니다.
final class InfiniteScrollFooterView: UICollectionReusableView {

    static let reuseIdentifier = "InfiniteScrollFooterView"
    static let height: CGFloat = 52

    private let activityIndicator = UIActivityIndicatorView(
        style: .medium
    )

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabel
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(
            arrangedSubviews: [activityIndicator, messageLabel]
        )
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(
                equalTo: centerXAnchor
            ),
            stackView.topAnchor.constraint(
                equalTo: topAnchor,
                constant: 8
            ),
            stackView.bottomAnchor.constraint(
                lessThanOrEqualTo: bottomAnchor,
                constant: -12
            )
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        activityIndicator.stopAnimating()
        messageLabel.text = nil
    }

    /// 다음 페이지 요청 상태에 맞는 진행 표시와 안내 문구를 설정합니다.
    func configure(
        isLoading: Bool
    ) {
        if isLoading {
            activityIndicator.startAnimating()
            messageLabel.text = "다음 페이지를 불러오는 중입니다"
            return
        }

        activityIndicator.stopAnimating()
        messageLabel.text = "스크롤하면 다음 페이지를 불러옵니다"
    }
}
