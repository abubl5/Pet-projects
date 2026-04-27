import UIKit

final class RecipeDetailViewController: UIViewController {
    private let recipeID: String
    private let store = BrewStore.shared

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    init(recipeID: String) {
        self.recipeID = recipeID
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var recipe: BrewRecipe {
        guard let recipe = store.recipe(withID: recipeID) else {
            fatalError("Missing recipe for id \(recipeID)")
        }
        return recipe
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.98, green: 0.96, blue: 0.93, alpha: 1.0)
        title = recipe.name
        navigationItem.largeTitleDisplayMode = .never

        configureLayout()
        render()
        updateFavoriteButton()
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
        let summaryCard = UIView()
        summaryCard.backgroundColor = .white
        summaryCard.layer.cornerRadius = 24

        let titleLabel = UILabel()
        titleLabel.text = recipe.method
        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = UIColor(red: 0.44, green: 0.26, blue: 0.15, alpha: 1.0)

        let summaryLabel = UILabel()
        summaryLabel.text = recipe.summary
        summaryLabel.font = .systemFont(ofSize: 28, weight: .bold)
        summaryLabel.numberOfLines = 0

        let statLabel = UILabel()
        statLabel.text = "\(recipe.coffeeGrams) г кофе  •  \(recipe.waterMilliliters) мл воды  •  \(recipe.temperatureCelsius)°C"
        statLabel.font = .systemFont(ofSize: 15, weight: .medium)
        statLabel.textColor = .secondaryLabel
        statLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [titleLabel, summaryLabel, statLabel])
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        summaryCard.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: summaryCard.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: summaryCard.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: summaryCard.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: summaryCard.bottomAnchor, constant: -20)
        ])

        contentStack.addArrangedSubview(summaryCard)
        contentStack.addArrangedSubview(makeTokenSection(title: "Вкусовой профиль", items: recipe.notes))

        let stepsCard = UIView()
        stepsCard.backgroundColor = .white
        stepsCard.layer.cornerRadius = 24

        let stepsStack = UIStackView()
        stepsStack.axis = .vertical
        stepsStack.spacing = 12
        stepsStack.translatesAutoresizingMaskIntoConstraints = false

        let heading = UILabel()
        heading.text = "Шаги"
        heading.font = .systemFont(ofSize: 22, weight: .bold)
        stepsStack.addArrangedSubview(heading)

        for (index, step) in recipe.steps.enumerated() {
            let label = UILabel()
            label.numberOfLines = 0
            label.font = .systemFont(ofSize: 16, weight: .medium)
            label.text = "\(index + 1). \(step.title) - \(step.duration) сек"
            stepsStack.addArrangedSubview(label)
        }

        stepsCard.addSubview(stepsStack)

        NSLayoutConstraint.activate([
            stepsStack.topAnchor.constraint(equalTo: stepsCard.topAnchor, constant: 20),
            stepsStack.leadingAnchor.constraint(equalTo: stepsCard.leadingAnchor, constant: 20),
            stepsStack.trailingAnchor.constraint(equalTo: stepsCard.trailingAnchor, constant: -20),
            stepsStack.bottomAnchor.constraint(equalTo: stepsCard.bottomAnchor, constant: -20)
        ])

        contentStack.addArrangedSubview(stepsCard)

        let timerButton = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = UIColor(red: 0.44, green: 0.26, blue: 0.15, alpha: 1.0)
        config.baseForegroundColor = .white
        config.cornerStyle = .large
        config.title = "Запустить таймер"
        config.image = UIImage(systemName: "timer")
        config.imagePadding = 10
        config.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 18, bottom: 16, trailing: 18)
        timerButton.configuration = config
        timerButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.navigationController?.pushViewController(BrewTimerViewController(recipe: self.recipe), animated: true)
        }, for: .touchUpInside)
        contentStack.addArrangedSubview(timerButton)
    }

    private func makeTokenSection(title: String, items: [String]) -> UIView {
        let container = UIView()
        container.backgroundColor = .white
        container.layer.cornerRadius = 24

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)

        let tokensLabel = UILabel()
        tokensLabel.text = items.map { "#\($0.replacingOccurrences(of: " ", with: "_"))" }.joined(separator: "   ")
        tokensLabel.textColor = UIColor(red: 0.44, green: 0.26, blue: 0.15, alpha: 1.0)
        tokensLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        tokensLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [titleLabel, tokensLabel])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20)
        ])

        return container
    }

    private func updateFavoriteButton() {
        let imageName = store.isFavorite(recipeID: recipe.id) ? "star.fill" : "star"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: imageName),
            style: .plain,
            target: self,
            action: #selector(toggleFavorite)
        )
    }

    @objc private func toggleFavorite() {
        store.toggleFavorite(recipeID: recipe.id)
        updateFavoriteButton()
    }
}
