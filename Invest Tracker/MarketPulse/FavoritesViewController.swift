import UIKit

final class FavoritesViewController: UITableViewController {
    private let store = MarketStore.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Избранное"
        tableView.backgroundColor = UIColor(red: 0.95, green: 0.98, blue: 0.96, alpha: 1.0)
        tableView.separatorStyle = .none
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 24, right: 0)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadFavorites),
            name: .marketStoreDidUpdate,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadFavorites()
    }

    @objc private func reloadFavorites() {
        tableView.reloadData()
        tableView.backgroundView = favoriteAssets.isEmpty ? makeEmptyStateView() : nil
    }

    private var favoriteAssets: [MarketAsset] {
        store.assets.filter { store.favoriteAssetIDs.contains($0.id) }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        favoriteAssets.count
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        108
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "FavoriteAssetCell"
        let asset = favoriteAssets[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell(style: .subtitle, reuseIdentifier: identifier)
        cell.backgroundConfiguration = UIBackgroundConfiguration.clear()
        cell.selectionStyle = .none

        let container = UIView()
        container.backgroundColor = .white
        container.layer.cornerRadius = 22
        container.frame = CGRect(x: 16, y: 6, width: tableView.bounds.width - 32, height: 96)
        cell.backgroundView = container

        var content = cell.defaultContentConfiguration()
        content.text = "\(asset.ticker) • \(asset.name)"
        content.secondaryText = "\(asset.sector)  •  \(String(format: "$%.2f", asset.price))  •  \(String(format: "%@%.1f%%", asset.dayChangePercent >= 0 ? "+" : "", asset.dayChangePercent))"
        content.textProperties.font = .systemFont(ofSize: 18, weight: .bold)
        content.secondaryTextProperties.font = .systemFont(ofSize: 14, weight: .medium)
        content.secondaryTextProperties.numberOfLines = 2
        cell.contentConfiguration = content
        cell.accessoryView = UIImageView(image: UIImage(systemName: "star.fill"))
        cell.accessoryView?.tintColor = UIColor(red: 0.89, green: 0.67, blue: 0.12, alpha: 1.0)

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        navigationController?.pushViewController(AssetDetailViewController(assetID: favoriteAssets[indexPath.row].id), animated: true)
    }

    private func makeEmptyStateView() -> UIView {
        let container = UIView()
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Пока ничего не добавлено.\nСохрани активы, которые хочешь отслеживать."
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 17, weight: .medium)
        container.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24)
        ])

        return container
    }
}
