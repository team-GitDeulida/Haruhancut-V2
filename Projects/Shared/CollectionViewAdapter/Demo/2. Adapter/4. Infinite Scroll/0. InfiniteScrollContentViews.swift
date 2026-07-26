import UIKit

/// 스크롤 중에도 화면 상단에 고정되는 section header입니다.
final class InfiniteScrollHeaderContentView: UIView {
    struct Item: Identifiable, Equatable {
        let id: String
        let title: String
        let loadedCount: Int
    }

    var item: Item? {
        didSet {
            guard item != oldValue else {
                return
            }
            applyItem()
        }
    }

    private let titleLabel = UILabel()
    private let countLabel = UILabel()
    private let pinLabel = UILabel()
    private let textStackView = UIStackView()
    private let separatorView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
        configureLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:)는 지원하지 않습니다.")
    }

    private func applyItem() {
        guard let item else {
            titleLabel.text = nil
            countLabel.text = nil
            return
        }

        titleLabel.text = item.title
        countLabel.text = "\(item.loadedCount)개 불러옴"
        accessibilityLabel =
            "\(item.title), \(item.loadedCount)개 불러옴, 고정 헤더"
    }

    private func configureView() {
        backgroundColor = .systemBackground

        titleLabel.font = .preferredFont(
            forTextStyle: .headline
        )
        titleLabel.textColor = .label
        titleLabel.adjustsFontForContentSizeCategory = true

        countLabel.font = .preferredFont(
            forTextStyle: .caption1
        )
        countLabel.textColor = .secondaryLabel
        countLabel.adjustsFontForContentSizeCategory = true

        pinLabel.text = "고정"
        pinLabel.font = .preferredFont(
            forTextStyle: .caption2
        )
        pinLabel.textColor = .black
        pinLabel.backgroundColor = .systemYellow
        pinLabel.textAlignment = .center
        pinLabel.layer.cornerRadius = 12
        pinLabel.layer.masksToBounds = true

        textStackView.axis = .vertical
        textStackView.spacing = 3
        textStackView.addArrangedSubview(titleLabel)
        textStackView.addArrangedSubview(countLabel)

        separatorView.backgroundColor = .separator
    }

    private func configureLayout() {
        textStackView.translatesAutoresizingMaskIntoConstraints =
            false
        pinLabel.translatesAutoresizingMaskIntoConstraints = false
        separatorView.translatesAutoresizingMaskIntoConstraints =
            false

        addSubview(textStackView)
        addSubview(pinLabel)
        addSubview(separatorView)

        NSLayoutConstraint.activate([
            textStackView.leadingAnchor.constraint(
                equalTo: leadingAnchor,
                constant: 20
            ),
            textStackView.centerYAnchor.constraint(
                equalTo: centerYAnchor
            ),
            textStackView.trailingAnchor.constraint(
                lessThanOrEqualTo: pinLabel.leadingAnchor,
                constant: -12
            ),

            pinLabel.trailingAnchor.constraint(
                equalTo: trailingAnchor,
                constant: -20
            ),
            pinLabel.centerYAnchor.constraint(
                equalTo: centerYAnchor
            ),
            pinLabel.widthAnchor.constraint(equalToConstant: 44),
            pinLabel.heightAnchor.constraint(equalToConstant: 24),

            separatorView.leadingAnchor.constraint(
                equalTo: leadingAnchor
            ),
            separatorView.trailingAnchor.constraint(
                equalTo: trailingAnchor
            ),
            separatorView.bottomAnchor.constraint(
                equalTo: bottomAnchor
            ),
            separatorView.heightAnchor.constraint(
                equalToConstant: 1 / UIScreen.main.scale
            ),
        ])
    }
}

/// 무한 스크롤 목록의 한 행을 표시합니다.
final class InfiniteScrollRowContentView: UIView {
    struct Item: Identifiable, Equatable {
        let id: Int
        let title: String
        let subtitle: String
        let page: Int
    }

    var item: Item? {
        didSet {
            guard item != oldValue else {
                return
            }
            applyItem()
        }
    }

    private let numberLabel = UILabel()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let textStackView = UIStackView()
    private let pageLabel = UILabel()
    private let separatorView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
        configureLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:)는 지원하지 않습니다.")
    }

    private func applyItem() {
        guard let item else {
            numberLabel.text = nil
            titleLabel.text = nil
            subtitleLabel.text = nil
            pageLabel.text = nil
            return
        }

        numberLabel.text = "\(item.id + 1)"
        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
        pageLabel.text = "\(item.page) 페이지"
        accessibilityLabel =
            "\(item.title), \(item.subtitle), \(item.page) 페이지"
    }

    private func configureView() {
        backgroundColor = .systemBackground

        numberLabel.font = .monospacedDigitSystemFont(
            ofSize: 16,
            weight: .bold
        )
        numberLabel.textColor = .black
        numberLabel.textAlignment = .center
        numberLabel.backgroundColor = .systemYellow
        numberLabel.layer.cornerRadius = 20
        numberLabel.layer.masksToBounds = true

        titleLabel.font = .preferredFont(
            forTextStyle: .body
        )
        titleLabel.textColor = .label
        titleLabel.adjustsFontForContentSizeCategory = true

        subtitleLabel.font = .preferredFont(
            forTextStyle: .caption1
        )
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.adjustsFontForContentSizeCategory = true

        textStackView.axis = .vertical
        textStackView.spacing = 4
        textStackView.addArrangedSubview(titleLabel)
        textStackView.addArrangedSubview(subtitleLabel)

        pageLabel.font = .preferredFont(
            forTextStyle: .caption2
        )
        pageLabel.textColor = .tertiaryLabel
        pageLabel.setContentCompressionResistancePriority(
            .required,
            for: .horizontal
        )

        separatorView.backgroundColor = .separator
    }

    private func configureLayout() {
        numberLabel.translatesAutoresizingMaskIntoConstraints =
            false
        textStackView.translatesAutoresizingMaskIntoConstraints =
            false
        pageLabel.translatesAutoresizingMaskIntoConstraints = false
        separatorView.translatesAutoresizingMaskIntoConstraints =
            false

        addSubview(numberLabel)
        addSubview(textStackView)
        addSubview(pageLabel)
        addSubview(separatorView)

        NSLayoutConstraint.activate([
            numberLabel.leadingAnchor.constraint(
                equalTo: leadingAnchor,
                constant: 20
            ),
            numberLabel.centerYAnchor.constraint(
                equalTo: centerYAnchor
            ),
            numberLabel.widthAnchor.constraint(equalToConstant: 40),
            numberLabel.heightAnchor.constraint(equalToConstant: 40),

            textStackView.leadingAnchor.constraint(
                equalTo: numberLabel.trailingAnchor,
                constant: 14
            ),
            textStackView.topAnchor.constraint(
                equalTo: topAnchor,
                constant: 14
            ),
            textStackView.bottomAnchor.constraint(
                equalTo: bottomAnchor,
                constant: -14
            ),
            textStackView.trailingAnchor.constraint(
                lessThanOrEqualTo: pageLabel.leadingAnchor,
                constant: -12
            ),

            pageLabel.trailingAnchor.constraint(
                equalTo: trailingAnchor,
                constant: -20
            ),
            pageLabel.centerYAnchor.constraint(
                equalTo: centerYAnchor
            ),

            separatorView.leadingAnchor.constraint(
                equalTo: textStackView.leadingAnchor
            ),
            separatorView.trailingAnchor.constraint(
                equalTo: trailingAnchor
            ),
            separatorView.bottomAnchor.constraint(
                equalTo: bottomAnchor
            ),
            separatorView.heightAnchor.constraint(
                equalToConstant: 1 / UIScreen.main.scale
            ),
        ])
    }
}

/// 다음 페이지를 불러오는 상태를 목록 끝에서 보여줍니다.
final class InfiniteScrollFooterContentView: UIView {
    struct Item: Identifiable, Equatable {
        let id: String
        let isLoading: Bool
    }

    var item: Item? {
        didSet {
            guard item != oldValue else {
                return
            }
            applyItem()
        }
    }

    private let activityIndicator = UIActivityIndicatorView(
        style: .medium
    )
    private let stateLabel = UILabel()
    private let stackView = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
        configureLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:)는 지원하지 않습니다.")
    }

    private func applyItem() {
        guard let item else {
            activityIndicator.stopAnimating()
            stateLabel.text = nil
            return
        }

        if item.isLoading {
            activityIndicator.startAnimating()
            stateLabel.text = "다음 페이지를 불러오는 중..."
        } else {
            activityIndicator.stopAnimating()
            stateLabel.text = "아래로 스크롤하면 계속 불러옵니다"
        }
    }

    private func configureView() {
        backgroundColor = .secondarySystemBackground

        activityIndicator.color = .secondaryLabel

        stateLabel.font = .preferredFont(
            forTextStyle: .footnote
        )
        stateLabel.textColor = .secondaryLabel
        stateLabel.adjustsFontForContentSizeCategory = true

        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 8
        stackView.addArrangedSubview(activityIndicator)
        stackView.addArrangedSubview(stateLabel)
    }

    private func configureLayout() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(
                equalTo: centerXAnchor
            ),
            stackView.centerYAnchor.constraint(
                equalTo: centerYAnchor
            ),
            stackView.leadingAnchor.constraint(
                greaterThanOrEqualTo: leadingAnchor,
                constant: 20
            ),
            stackView.trailingAnchor.constraint(
                lessThanOrEqualTo: trailingAnchor,
                constant: -20
            ),
        ])
    }
}
