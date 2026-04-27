import UIKit

final class AssetCell: UICollectionViewCell {
    static let reuseIdentifier = "AssetCell"

    private let tickerLabel = UILabel()
    private let nameLabel = UILabel()
    private let sectorLabel = UILabel()
    private let priceLabel = UILabel()
    private let changeLabel = UILabel()
    private let favoriteIcon = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 24

        tickerLabel.font = .systemFont(ofSize: 24, weight: .bold)
        nameLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        nameLabel.textColor = .secondaryLabel
        nameLabel.numberOfLines = 2
        sectorLabel.font = .systemFont(ofSize: 13, weight: .medium)
        sectorLabel.textColor = UIColor(red: 0.09, green: 0.33, blue: 0.24, alpha: 1.0)
        priceLabel.font = .systemFont(ofSize: 18, weight: .bold)
        changeLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        favoriteIcon.tintColor = UIColor(red: 0.89, green: 0.67, blue: 0.12, alpha: 1.0)

        let stack = UIStackView(arrangedSubviews: [favoriteIcon, tickerLabel, nameLabel, sectorLabel, priceLabel, changeLabel])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -16)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with asset: MarketAsset, isFavorite: Bool) {
        favoriteIcon.image = UIImage(systemName: isFavorite ? "star.fill" : "chart.line.uptrend.xyaxis")
        tickerLabel.text = asset.ticker
        nameLabel.text = asset.name
        sectorLabel.text = asset.sector
        priceLabel.text = String(format: "$%.2f", asset.price)
        changeLabel.text = String(format: "%@%.1f%% за день", asset.dayChangePercent >= 0 ? "+" : "", asset.dayChangePercent)
        changeLabel.textColor = asset.dayChangePercent >= 0
            ? UIColor(red: 0.08, green: 0.52, blue: 0.33, alpha: 1.0)
            : UIColor(red: 0.72, green: 0.2, blue: 0.2, alpha: 1.0)
    }
}
