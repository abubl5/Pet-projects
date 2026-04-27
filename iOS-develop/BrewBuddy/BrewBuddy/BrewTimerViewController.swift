import UIKit

final class BrewTimerViewController: UIViewController {
    private let recipe: BrewRecipe

    private let timerLabel = UILabel()
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let startPauseButton = UIButton(type: .system)
    private let stackView = UIStackView()

    private var timer: Timer?
    private var remainingSeconds: Int
    private var isRunning = false

    init(recipe: BrewRecipe) {
        self.recipe = recipe
        self.remainingSeconds = recipe.duration
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        timer?.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Таймер"
        view.backgroundColor = UIColor(red: 0.98, green: 0.96, blue: 0.93, alpha: 1.0)
        configureLayout()
        updateTimerUI()
    }

    private func configureLayout() {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = .white
        card.layer.cornerRadius = 28

        timerLabel.font = .monospacedDigitSystemFont(ofSize: 44, weight: .bold)
        timerLabel.textAlignment = .center

        progressView.progressTintColor = UIColor(red: 0.44, green: 0.26, blue: 0.15, alpha: 1.0)
        progressView.trackTintColor = UIColor(red: 0.93, green: 0.89, blue: 0.84, alpha: 1.0)
        progressView.layer.cornerRadius = 6
        progressView.clipsToBounds = true
        progressView.transform = CGAffineTransform(scaleX: 1, y: 3)

        let subtitleLabel = UILabel()
        subtitleLabel.text = recipe.name
        subtitleLabel.textAlignment = .center
        subtitleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        subtitleLabel.textColor = .secondaryLabel

        stackView.axis = .vertical
        stackView.spacing = 10

        let stepsTitle = UILabel()
        stepsTitle.text = "Этапы рецепта"
        stepsTitle.font = .systemFont(ofSize: 20, weight: .bold)
        stackView.addArrangedSubview(stepsTitle)

        for step in recipe.steps {
            let label = UILabel()
            label.numberOfLines = 0
            label.font = .systemFont(ofSize: 16, weight: .medium)
            label.text = "• \(step.title) (\(step.duration) сек)"
            stackView.addArrangedSubview(label)
        }

        startPauseButton.configuration = makeButtonConfiguration(title: "Старт")
        startPauseButton.addAction(UIAction { [weak self] _ in
            self?.toggleTimer()
        }, for: .touchUpInside)

        let finishButton = UIButton(type: .system)
        finishButton.configuration = makeButtonConfiguration(title: "Завершить", filled: false)
        finishButton.addAction(UIAction { [weak self] _ in
            self?.finishBrewing()
        }, for: .touchUpInside)

        let actions = UIStackView(arrangedSubviews: [startPauseButton, finishButton])
        actions.axis = .vertical
        actions.spacing = 12
        actions.translatesAutoresizingMaskIntoConstraints = false

        let recipeStack = UIStackView(arrangedSubviews: [subtitleLabel, timerLabel, progressView, stackView, actions])
        recipeStack.axis = .vertical
        recipeStack.spacing = 18
        recipeStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(card)
        card.addSubview(recipeStack)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            recipeStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 24),
            recipeStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            recipeStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            recipeStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -24),
            actions.heightAnchor.constraint(equalToConstant: 112)
        ])
    }

    private func makeButtonConfiguration(title: String, filled: Bool = true) -> UIButton.Configuration {
        var config = filled ? UIButton.Configuration.filled() : UIButton.Configuration.tinted()
        config.title = title
        config.cornerStyle = .large
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 18, bottom: 14, trailing: 18)
        config.baseBackgroundColor = filled ? UIColor(red: 0.44, green: 0.26, blue: 0.15, alpha: 1.0) : UIColor(red: 0.96, green: 0.9, blue: 0.82, alpha: 1.0)
        config.baseForegroundColor = filled ? .white : UIColor(red: 0.44, green: 0.26, blue: 0.15, alpha: 1.0)
        return config
    }

    private func toggleTimer() {
        isRunning.toggle()

        if isRunning {
            startPauseButton.configuration = makeButtonConfiguration(title: "Пауза")
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                self?.tick()
            }
        } else {
            timer?.invalidate()
            startPauseButton.configuration = makeButtonConfiguration(title: "Продолжить")
        }
    }

    private func tick() {
        guard remainingSeconds > 0 else {
            finishBrewing()
            return
        }

        remainingSeconds -= 1
        updateTimerUI()

        if remainingSeconds == 0 {
            finishBrewing()
        }
    }

    private func updateTimerUI() {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        timerLabel.text = String(format: "%02d:%02d", minutes, seconds)
        progressView.progress = 1 - Float(remainingSeconds) / Float(recipe.duration)
    }

    private func finishBrewing() {
        timer?.invalidate()
        isRunning = false
        navigationController?.pushViewController(SessionReviewViewController(recipe: recipe), animated: true)
    }
}
