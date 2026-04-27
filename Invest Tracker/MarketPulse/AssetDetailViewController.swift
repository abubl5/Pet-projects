import UIKit

final class AssetDetailViewController: UIViewController {
    private let assetID: String
    private let store = MarketStore.shared

    init(assetID: String) {
        self.assetID = assetID
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var asset: MarketAsset {
        guard let asset = store.asset(withID: assetID) else {
            fatalError("Missing asset \(assetID)")
        }
        return asset
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = asset.ticker
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = UIColor(red: 0.95, green: 0.98, blue: 0.96, alpha: 1.0)
        updateFavoriteButton()
        configureLayout()
    }

    private func configureLayout() {
        let scrollView = UIScrollView()
        let stack = UIStackView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 16

        view.addSubview(scrollView)
        scrollView.addSubview(stack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24)
        ])

        stack.addArrangedSubview(makeCard(title: asset.name, body: asset.summary, accent: true))
        stack.addArrangedSubview(makeCard(title: "Цена", body: String(format: "$%.2f", asset.price)))
        stack.addArrangedSubview(makeCard(title: "Изменение за день", body: formatChange(asset.dayChangePercent)))
        stack.addArrangedSubview(makeCard(title: "Изменение за месяц", body: formatChange(asset.monthlyChangePercent)))
        stack.addArrangedSubview(makeListCard(title: "Почему может быть интересен", items: asset.thesis))
        stack.addArrangedSubview(makeListCard(title: "Риски", items: asset.risks))
    }

    private func makeCard(title: String, body: String, accent: Bool = false) -> UIView {
        let card = UIView()
        card.backgroundColor = accent ? UIColor(red: 0.1, green: 0.37, blue: 0.26, alpha: 1.0) : .white
        card.layer.cornerRadius = 24

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = accent ? UIColor(red: 0.83, green: 0.96, blue: 0.9, alpha: 1.0) : .secondaryLabel

        let bodyLabel = UILabel()
        bodyLabel.text = body
        bodyLabel.font = .systemFont(ofSize: accent ? 26 : 18, weight: accent ? .bold : .medium)
        bodyLabel.numberOfLines = 0
        bodyLabel.textColor = accent ? .white : .label

        let stack = UIStackView(arrangedSubviews: [titleLabel, bodyLabel])
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

    private func makeListCard(title: String, items: [String]) -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 24

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(titleLabel)

        for item in items {
            let label = UILabel()
            label.numberOfLines = 0
            label.font = .systemFont(ofSize: 16, weight: .medium)
            label.text = "• \(item)"
            stack.addArrangedSubview(label)
        }

        card.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20)
        ])

        return card
    }

    private func updateFavoriteButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: store.isFavorite(id: asset.id) ? "star.fill" : "star"),
            style: .plain,
            target: self,
            action: #selector(toggleFavorite)
        )
    }

    @objc private func toggleFavorite() {
        store.toggleFavorite(id: asset.id)
        updateFavoriteButton()
    }

    private func formatChange(_ value: Double) -> String {
        String(format: "%@%.1f%%", value >= 0 ? "+" : "", value)
    }
}
