import UIKit

final class HomeViewController: UIViewController {
    private let store = BrewStore.shared
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "BrewBuddy"
        view.backgroundColor = UIColor(red: 0.98, green: 0.96, blue: 0.93, alpha: 1.0)
        navigationItem.largeTitleDisplayMode = .always

        configureLayout()
        rebuildContent()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleStoreUpdate),
            name: .brewStoreDidUpdate,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        rebuildContent()
    }

    @objc private func handleStoreUpdate() {
        rebuildContent()
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

    private func rebuildContent() {
        contentStack.arrangedSubviews.forEach {
            contentStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        contentStack.addArrangedSubview(makeHeroCard())
        contentStack.addArrangedSubview(makeSectionTitle("Рекомендуемые рецепты"))

        for recipe in store.recipes.prefix(3) {
            contentStack.addArrangedSubview(makeRecipeCard(for: recipe))
        }

        contentStack.addArrangedSubview(makeSectionTitle("Быстрые действия"))
        contentStack.addArrangedSubview(makeActionButton(title: "Открыть все методы", icon: "cup.and.saucer.fill") { [weak self] in
            self?.tabBarController?.selectedIndex = 1
        })
        contentStack.addArrangedSubview(makeActionButton(title: "Открыть историю", icon: "clock.fill") { [weak self] in
            self?.tabBarController?.selectedIndex = 2
        })

        if let latestSession = store.sessions.first {
            contentStack.addArrangedSubview(makeSectionTitle("Последняя сессия"))
            contentStack.addArrangedSubview(makeSessionCard(session: latestSession))
        }
    }

    private func makeHeroCard() -> UIView {
        let card = UIView()
        card.backgroundColor = UIColor(red: 0.31, green: 0.2, blue: 0.14, alpha: 1.0)
        card.layer.cornerRadius = 24

        let titleLabel = UILabel()
        titleLabel.text = "Преврати каждую чашку кофе в маленький ритуал."
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 0

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Рецепты, таймер, дегустационные заметки и история приготовлений в одном месте."
        subtitleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.85)
        subtitleLabel.numberOfLines = 0

        let badgeLabel = UILabel()
        badgeLabel.text = "В избранном: \(store.favoriteRecipeIDs.count)"
        badgeLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        badgeLabel.textColor = UIColor(red: 0.31, green: 0.2, blue: 0.14, alpha: 1.0)
        badgeLabel.backgroundColor = UIColor(red: 0.94, green: 0.82, blue: 0.66, alpha: 1.0)
        badgeLabel.textAlignment = .center
        badgeLabel.layer.cornerRadius = 12
        badgeLabel.layer.masksToBounds = true

        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, badgeLabel])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 12

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

    private func makeRecipeCard(for recipe: BrewRecipe) -> UIView {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = .white
        config.baseForegroundColor = .label
        config.cornerStyle = .large
        config.contentInsets = NSDirectionalEdgeInsets(top: 18, leading: 18, bottom: 18, trailing: 18)
        config.title = "\(recipe.name)\n\(recipe.summary)"
        config.subtitle = "\(recipe.method)  •  \(recipe.duration / 60) мин  •  \(recipe.coffeeGrams) г кофе"
        config.image = UIImage(systemName: store.isFavorite(recipeID: recipe.id) ? "star.fill" : "arrow.right.circle.fill")
        config.imagePlacement = .trailing
        config.imagePadding = 10
        config.titleAlignment = .leading
        button.configuration = config
        button.contentHorizontalAlignment = .leading
        button.layer.cornerRadius = 22
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.05
        button.layer.shadowOffset = CGSize(width: 0, height: 8)
        button.layer.shadowRadius = 20
        button.addAction(UIAction { [weak self] _ in
            self?.navigationController?.pushViewController(RecipeDetailViewController(recipeID: recipe.id), animated: true)
        }, for: .touchUpInside)
        return button
    }

    private func makeActionButton(title: String, icon: String, action: @escaping () -> Void) -> UIView {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.tinted()
        config.baseForegroundColor = UIColor(red: 0.44, green: 0.26, blue: 0.15, alpha: 1.0)
        config.baseBackgroundColor = UIColor(red: 0.96, green: 0.9, blue: 0.82, alpha: 1.0)
        config.cornerStyle = .large
        config.image = UIImage(systemName: icon)
        config.imagePadding = 10
        config.title = title
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16)
        button.configuration = config
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        return button
    }

    private func makeSessionCard(session: BrewSession) -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 22

        let titleLabel = UILabel()
        titleLabel.text = session.recipeName
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)

        let dateLabel = UILabel()
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        dateLabel.text = formatter.string(from: session.brewedAt)
        dateLabel.textColor = .secondaryLabel
        dateLabel.font = .systemFont(ofSize: 14, weight: .medium)

        let noteLabel = UILabel()
        noteLabel.text = "Вкус: \(session.tastingNote)\nЗаметки: \(session.journalNote)"
        noteLabel.numberOfLines = 0
        noteLabel.font = .systemFont(ofSize: 15)

        let ratingLabel = UILabel()
        ratingLabel.text = String(repeating: "★", count: session.rating)
        ratingLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        ratingLabel.textColor = UIColor(red: 0.86, green: 0.58, blue: 0.17, alpha: 1.0)

        let stack = UIStackView(arrangedSubviews: [titleLabel, dateLabel, noteLabel, ratingLabel])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 8

        card.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18)
        ])

        return card
    }
}
