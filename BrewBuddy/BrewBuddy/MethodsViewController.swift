import UIKit

final class MethodsViewController: UITableViewController {
    private let store = BrewStore.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Методы"
        tableView.backgroundColor = UIColor(red: 0.98, green: 0.96, blue: 0.93, alpha: 1.0)
        tableView.separatorStyle = .none
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 24, right: 0)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadDataSource),
            name: .brewStoreDidUpdate,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    @objc private func reloadDataSource() {
        tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        store.recipes.count
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        112
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "MethodCell"
        let recipe = store.recipes[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell(style: .subtitle, reuseIdentifier: identifier)

        var content = cell.defaultContentConfiguration()
        content.text = recipe.name
        content.secondaryText = "\(recipe.method)  •  \(recipe.summary)"
        content.textProperties.font = .systemFont(ofSize: 18, weight: .bold)
        content.secondaryTextProperties.font = .systemFont(ofSize: 14, weight: .medium)
        content.secondaryTextProperties.color = .secondaryLabel
        content.secondaryTextProperties.numberOfLines = 2
        cell.contentConfiguration = content

        cell.backgroundConfiguration = UIBackgroundConfiguration.clear()
        let container = UIView()
        container.backgroundColor = .white
        container.layer.cornerRadius = 22
        container.layer.masksToBounds = true
        container.frame = CGRect(x: 16, y: 6, width: tableView.bounds.width - 32, height: 100)
        cell.backgroundView = container
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .none

        if store.isFavorite(recipeID: recipe.id) {
            cell.accessoryView = UIImageView(image: UIImage(systemName: "star.fill"))
            cell.accessoryView?.tintColor = UIColor(red: 0.86, green: 0.58, blue: 0.17, alpha: 1.0)
        } else {
            cell.accessoryView = UIImageView(image: UIImage(systemName: "chevron.right"))
            cell.accessoryView?.tintColor = .tertiaryLabel
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let recipe = store.recipes[indexPath.row]
        navigationController?.pushViewController(RecipeDetailViewController(recipeID: recipe.id), animated: true)
    }
}
