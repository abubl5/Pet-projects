import UIKit

final class OverviewViewController: UIViewController {
    private let store = MarketStore.shared
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "MarketPulse"
        view.backgroundColor = UIColor(red: 0.95, green: 0.98, blue: 0.96, alpha: 1.0)
        navigationItem.largeTitleDisplayMode = .always
        configureLayout()
        render()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadViewData),
            name: .marketStoreDidUpdate,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func reloadViewData() {
        render()
    }

    private func configureLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 16

        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24)
        ])
    }

    private func render() {
        contentStack.arrangedSubviews.forEach {
            contentStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        contentStack.addArrangedSubview(makeHeroCard())
        contentStack.addArrangedSubview(makeSectionTitle("Лидеры дня"))

        for asset in store.assets.sorted(by: { $0.dayChangePercent > $1.dayChangePercent }).prefix(3) {
            contentStack.addArrangedSubview(makeAssetRow(asset))
        }

        contentStack.addArrangedSubview(makeSectionTitle("Быстрые действия"))
        contentStack.addArrangedSubview(makeActionButton(title: "Открыть список активов", icon: "list.bullet") { [weak self] in
            self?.tabBarController?.selectedIndex = 1
        })
        contentStack.addArrangedSubview(makeActionButton(title: "Посмотреть сектора", icon: "square.grid.2x2") { [weak self] in
            self?.tabBarController?.selectedIndex = 2
        })

        contentStack.addArrangedSubview(makeSectionTitle("Фокус недели"))
        if let featured = store.assets.first(where: { $0.ticker == "NVDA" }) {
            contentStack.addArrangedSubview(makeFeatureCard(asset: featured))
        }
    }

    private func makeHeroCard() -> UIView {
        let card = UIView()
        card.backgroundColor = UIColor(red: 0.09, green: 0.33, blue: 0.24, alpha: 1.0)
        card.layer.cornerRadius = 28

        let titleLabel = UILabel()
        titleLabel.text = "Следи за рынком без перегруза."
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 0

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Короткий обзор дня, список активов, сектора и избранное в одном приложении."
        subtitleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.84)
        subtitleLabel.numberOfLines = 0

        let badgeLabel = UILabel()
        badgeLabel.text = "В избранном: \(store.favoriteAssetIDs.count)"
        badgeLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        badgeLabel.textAlignment = .center
        badgeLabel.backgroundColor = UIColor(red: 0.78, green: 0.94, blue: 0.86, alpha: 1.0)
        badgeLabel.textColor = UIColor(red: 0.09, green: 0.33, blue: 0.24, alpha: 1.0)
        badgeLabel.layer.cornerRadius = 12
        badgeLabel.layer.masksToBounds = true

        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, badgeLabel])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        NSLayoutConstraint.activate([
            badgeLabel.heightAnchor.constraint(equalToConstant: 34),
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -24)
        ])

        return card
    }

    private func makeSectionTitle(_ title: String) -> UILabel {
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 22, weight: .bold)
        return label
    }

    private func makeAssetRow(_ asset: MarketAsset) -> UIView {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = .white
        config.baseForegroundColor = .label
        config.cornerStyle = .large
        config.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 18, bottom: 16, trailing: 18)
        config.title = "\(asset.ticker) • \(asset.name)"
        config.subtitle = "\(asset.sector)  •  \(formatPrice(asset.price))  •  \(formatChange(asset.dayChangePercent))"
        config.titleAlignment = .leading
        config.image = UIImage(systemName: "arrow.right.circle.fill")
        config.imagePlacement = .trailing
        config.imagePadding = 10
        button.configuration = config
        button.contentHorizontalAlignment = .leading
        button.addAction(UIAction { [weak self] _ in
            self?.navigationController?.pushViewController(AssetDetailViewController(assetID: asset.id), animated: true)
        }, for: .touchUpInside)
        return button
    }

    private func makeFeatureCard(asset: MarketAsset) -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 24

        let titleLabel = UILabel()
        titleLabel.text = "\(asset.ticker) как идея для наблюдения"
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.numberOfLines = 0

        let bodyLabel = UILabel()
        bodyLabel.text = asset.summary
        bodyLabel.font = .systemFont(ofSize: 16, weight: .medium)
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.numberOfLines = 0

        let metricsLabel = UILabel()
        metricsLabel.text = "День: \(formatChange(asset.dayChangePercent))   •   Месяц: \(formatChange(asset.monthlyChangePercent))"
        metricsLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        metricsLabel.textColor = UIColor(red: 0.08, green: 0.52, blue: 0.33, alpha: 1.0)
        metricsLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [titleLabel, bodyLabel, metricsLabel])
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20)
        ])

        return card
    }

    private func makeActionButton(title: String, icon: String, action: @escaping () -> Void) -> UIView {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.tinted()
        config.baseForegroundColor = UIColor(red: 0.09, green: 0.33, blue: 0.24, alpha: 1.0)
        config.baseBackgroundColor = UIColor(red: 0.85, green: 0.95, blue: 0.9, alpha: 1.0)
        config.cornerStyle = .large
        config.title = title
        config.image = UIImage(systemName: icon)
        config.imagePadding = 10
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16)
        button.configuration = config
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        return button
    }

    private func formatPrice(_ value: Double) -> String {
        String(format: "$%.2f", value)
    }

    private func formatChange(_ value: Double) -> String {
        String(format: "%@%.1f%%", value >= 0 ? "+" : "", value)
    }
}
