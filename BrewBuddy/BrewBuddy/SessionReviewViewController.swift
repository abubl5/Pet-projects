import UIKit

final class SessionReviewViewController: UIViewController {
    private let recipe: BrewRecipe
    private let ratingControl = UISegmentedControl(items: ["1", "2", "3", "4", "5"])
    private let tastingField = UITextField()
    private let notesView = UITextView()

    init(recipe: BrewRecipe) {
        self.recipe = recipe
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Оценка сессии"
        view.backgroundColor = UIColor(red: 0.98, green: 0.96, blue: 0.93, alpha: 1.0)
        ratingControl.selectedSegmentIndex = 3
        configureLayout()
    }

    private func configureLayout() {
        let scrollView = UIScrollView()
        let stack = UIStackView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 18

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

        stack.addArrangedSubview(makeCard(title: "Рецепт", content: recipe.name))

        let ratingCard = UIView()
        ratingCard.backgroundColor = .white
        ratingCard.layer.cornerRadius = 24
        let ratingStack = UIStackView(arrangedSubviews: [makeTitleLabel("Насколько хорошо получилось?"), ratingControl])
        ratingStack.axis = .vertical
        ratingStack.spacing = 14
        ratingStack.translatesAutoresizingMaskIntoConstraints = false
        ratingCard.addSubview(ratingStack)

        NSLayoutConstraint.activate([
            ratingStack.topAnchor.constraint(equalTo: ratingCard.topAnchor, constant: 20),
            ratingStack.leadingAnchor.constraint(equalTo: ratingCard.leadingAnchor, constant: 20),
            ratingStack.trailingAnchor.constraint(equalTo: ratingCard.trailingAnchor, constant: -20),
            ratingStack.bottomAnchor.constraint(equalTo: ratingCard.bottomAnchor, constant: -20)
        ])
        stack.addArrangedSubview(ratingCard)

        tastingField.placeholder = "Главная вкусовая нота"
        tastingField.borderStyle = .roundedRect
        tastingField.backgroundColor = UIColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1.0)

        let tastingCard = UIView()
        tastingCard.backgroundColor = .white
        tastingCard.layer.cornerRadius = 24
        let tastingStack = UIStackView(arrangedSubviews: [makeTitleLabel("Вкусовая нота"), tastingField])
        tastingStack.axis = .vertical
        tastingStack.spacing = 14
        tastingStack.translatesAutoresizingMaskIntoConstraints = false
        tastingCard.addSubview(tastingStack)

        NSLayoutConstraint.activate([
            tastingStack.topAnchor.constraint(equalTo: tastingCard.topAnchor, constant: 20),
            tastingStack.leadingAnchor.constraint(equalTo: tastingCard.leadingAnchor, constant: 20),
            tastingStack.trailingAnchor.constraint(equalTo: tastingCard.trailingAnchor, constant: -20),
            tastingStack.bottomAnchor.constraint(equalTo: tastingCard.bottomAnchor, constant: -20)
        ])
        stack.addArrangedSubview(tastingCard)

        notesView.font = .systemFont(ofSize: 16)
        notesView.layer.cornerRadius = 14
        notesView.backgroundColor = UIColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1.0)
        notesView.text = "Что изменилось в рецепте? Что бы ты повторил в следующий раз?"
        notesView.textColor = .secondaryLabel
        notesView.delegate = self
        notesView.heightAnchor.constraint(equalToConstant: 140).isActive = true

        let notesCard = UIView()
        notesCard.backgroundColor = .white
        notesCard.layer.cornerRadius = 24
        let notesStack = UIStackView(arrangedSubviews: [makeTitleLabel("Заметка"), notesView])
        notesStack.axis = .vertical
        notesStack.spacing = 14
        notesStack.translatesAutoresizingMaskIntoConstraints = false
        notesCard.addSubview(notesStack)

        NSLayoutConstraint.activate([
            notesStack.topAnchor.constraint(equalTo: notesCard.topAnchor, constant: 20),
            notesStack.leadingAnchor.constraint(equalTo: notesCard.leadingAnchor, constant: 20),
            notesStack.trailingAnchor.constraint(equalTo: notesCard.trailingAnchor, constant: -20),
            notesStack.bottomAnchor.constraint(equalTo: notesCard.bottomAnchor, constant: -20)
        ])
        stack.addArrangedSubview(notesCard)

        let saveButton = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = UIColor(red: 0.44, green: 0.26, blue: 0.15, alpha: 1.0)
        config.baseForegroundColor = .white
        config.cornerStyle = .large
        config.title = "Сохранить сессию"
        config.image = UIImage(systemName: "checkmark.circle.fill")
        config.imagePadding = 10
        config.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 18, bottom: 16, trailing: 18)
        saveButton.configuration = config
        saveButton.addAction(UIAction { [weak self] _ in
            self?.saveSession()
        }, for: .touchUpInside)
        stack.addArrangedSubview(saveButton)
    }

    private func makeCard(title: String, content: String) -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 24

        let stack = UIStackView(arrangedSubviews: [makeTitleLabel(title), makeBodyLabel(content)])
        stack.axis = .vertical
        stack.spacing = 12
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

    private func makeTitleLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 20, weight: .bold)
        return label
    }

    private func makeBodyLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
        return label
    }

    private func saveSession() {
        let rating = ratingControl.selectedSegmentIndex + 1
        let tastingNote = tastingField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            ? tastingField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            : "Сбалансированная чашка"
        let journalNote = notesView.textColor == .secondaryLabel ? "" : notesView.text.trimmingCharacters(in: .whitespacesAndNewlines)

        BrewStore.shared.addSession(
            BrewSession(
                id: UUID(),
                recipeID: recipe.id,
                recipeName: recipe.name,
                brewedAt: Date(),
                rating: rating,
                tastingNote: tastingNote,
                journalNote: journalNote
            )
        )

        tabBarController?.selectedIndex = 2
        navigationController?.popToRootViewController(animated: false)
    }
}

extension SessionReviewViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .secondaryLabel {
            textView.text = ""
            textView.textColor = .label
        }
    }
}
