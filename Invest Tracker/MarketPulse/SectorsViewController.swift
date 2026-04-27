import UIKit

final class SectorsViewController: UITableViewController {
    private let store = MarketStore.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Сектора"
        tableView.backgroundColor = UIColor(red: 0.95, green: 0.98, blue: 0.96, alpha: 1.0)
        tableView.separatorStyle = .none
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 24, right: 0)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        store.sectors.count
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        116
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "SectorCell"
        let sector = store.sectors[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell(style: .subtitle, reuseIdentifier: identifier)

        var content = cell.defaultContentConfiguration()
        content.text = sector.title
        content.secondaryText = "День: \(formatChange(sector.changePercent))\nЛидеры: \(sector.leaders.joined(separator: ", "))"
        content.textProperties.font = .systemFont(ofSize: 18, weight: .bold)
        content.secondaryTextProperties.font = .systemFont(ofSize: 14, weight: .medium)
        content.secondaryTextProperties.numberOfLines = 2
        cell.contentConfiguration = content
        cell.backgroundConfiguration = UIBackgroundConfiguration.clear()
        cell.selectionStyle = .none

        let container = UIView()
        container.backgroundColor = .white
        container.layer.cornerRadius = 22
        container.frame = CGRect(x: 16, y: 6, width: tableView.bounds.width - 32, height: 104)
        cell.backgroundView = container
        return cell
    }

    private func formatChange(_ value: Double) -> String {
        String(format: "%@%.1f%%", value >= 0 ? "+" : "", value)
    }
}
