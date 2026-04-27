import UIKit

final class BrewRootViewController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let home = UINavigationController(rootViewController: HomeViewController())
        home.tabBarItem = UITabBarItem(title: "Главная", image: UIImage(systemName: "house.fill"), tag: 0)

        let methods = UINavigationController(rootViewController: MethodsViewController())
        methods.tabBarItem = UITabBarItem(title: "Методы", image: UIImage(systemName: "list.bullet.rectangle"), tag: 1)

        let history = UINavigationController(rootViewController: HistoryViewController())
        history.tabBarItem = UITabBarItem(title: "История", image: UIImage(systemName: "clock.arrow.circlepath"), tag: 2)

        setViewControllers([home, methods, history], animated: false)
        tabBar.tintColor = UIColor(red: 0.44, green: 0.26, blue: 0.15, alpha: 1.0)
    }
}
