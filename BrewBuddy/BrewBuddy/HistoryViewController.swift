import UIKit

final class HistoryViewController: UITableViewController {
    private let store = BrewStore.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "История"
        tableView.backgroundColor = UIColor(red: 0.98, green: 0.96, blue: 0.93, alpha: 1.0)
        tableView.separatorStyle = .none
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 24, right: 0)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadHistory),
            name: .brewStoreDidUpdate,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadHistory()
    }

    @objc private func reloadHistory() {
        tableView.reloadData()
        tableView.backgroundView = store.sessions.isEmpty ? makeEmptyStateView() : nil
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        store.sessions.count
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        128
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "HistoryCell"
        let session = store.sessions[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell(style: .subtitle, reuseIdentifier: identifier)

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        var content = cell.defaultContentConfiguration()
        content.text = "\(session.recipeName)  \(String(repeating: "★", count: session.rating))"
        content.secondaryText = "\(formatter.string(from: session.brewedAt))\nВкус: \(session.tastingNote)"
        content.textProperties.font = .systemFont(ofSize: 18, weight: .bold)
        content.secondaryTextProperties.font = .systemFont(ofSize: 14, weight: .medium)
        content.secondaryTextProperties.color = .secondaryLabel
        content.secondaryTextProperties.numberOfLines = 2
        cell.contentConfiguration = content
        cell.backgroundConfiguration = UIBackgroundConfiguration.clear()

        let container = UIView()
        container.backgroundColor = .white
        container.layer.cornerRadius = 22
        container.frame = CGRect(x: 16, y: 6, width: tableView.bounds.width - 32, height: 116)
        cell.backgroundView = container
        cell.selectionStyle = .none
        return cell
    }

    private func makeEmptyStateView() -> UIView {
        let container = UIView()
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Пока нет приготовлений.\nЗапусти таймер рецепта и сохрани первую дегустационную заметку"
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
