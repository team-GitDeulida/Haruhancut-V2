import UIKit

final class DemoCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = String(describing: DemoCollectionViewCell.self)

    private let symbolContainerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 22
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let symbolImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .bold)
        label.textColor = .label
        label.numberOfLines = 2
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = .secondaryLabel
        label.numberOfLines = 2
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureHierarchy()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        layer.removeAllAnimations()
        transform = .identity
    }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.16) {
                self.transform = self.isHighlighted
                    ? CGAffineTransform(scaleX: 0.97, y: 0.97)
                    : .identity
            }
        }
    }

    func configure(with item: DemoItem) {
        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
        symbolImageView.image = UIImage(systemName: item.symbolName)
        symbolImageView.tintColor = item.tintColor
        symbolContainerView.backgroundColor = item.tintColor.withAlphaComponent(0.14)
    }

    private func configureHierarchy() {
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 18
        layer.cornerCurve = .continuous
        layer.borderColor = UIColor.separator.withAlphaComponent(0.3).cgColor
        layer.borderWidth = 0.5

        symbolContainerView.addSubview(symbolImageView)

        let textStackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStackView.axis = .vertical
        textStackView.spacing = 5
        textStackView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(symbolContainerView)
        contentView.addSubview(textStackView)

        NSLayoutConstraint.activate([
            symbolContainerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            symbolContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            symbolContainerView.widthAnchor.constraint(equalToConstant: 44),
            symbolContainerView.heightAnchor.constraint(equalToConstant: 44),

            symbolImageView.centerXAnchor.constraint(equalTo: symbolContainerView.centerXAnchor),
            symbolImageView.centerYAnchor.constraint(equalTo: symbolContainerView.centerYAnchor),
            symbolImageView.widthAnchor.constraint(equalToConstant: 22),
            symbolImageView.heightAnchor.constraint(equalToConstant: 22),

            textStackView.topAnchor.constraint(equalTo: symbolContainerView.bottomAnchor, constant: 12),
            textStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            textStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            textStackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -14)
        ])
    }
}
