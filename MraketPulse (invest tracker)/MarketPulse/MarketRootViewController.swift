import UIKit

final class MarketRootViewController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let overview = UINavigationController(rootViewController: OverviewViewController())
        overview.tabBarItem = UITabBarItem(title: "Обзор", image: UIImage(systemName: "chart.line.uptrend.xyaxis"), tag: 0)

        let watchlist = UINavigationController(rootViewController: WatchlistViewController())
        watchlist.tabBarItem = UITabBarItem(title: "Активы", image: UIImage(systemName: "list.bullet.rectangle.portrait"), tag: 1)

        let sectors = UINavigationController(rootViewController: SectorsViewController())
        sectors.tabBarItem = UITabBarItem(title: "Сектора", image: UIImage(systemName: "square.grid.2x2"), tag: 2)

        let favorites = UINavigationController(rootViewController: FavoritesViewController())
        favorites.tabBarItem = UITabBarItem(title: "Избранное", image: UIImage(systemName: "star.fill"), tag: 3)

        setViewControllers([overview, watchlist, sectors, favorites], animated: false)
        tabBar.tintColor = UIColor(red: 0.08, green: 0.52, blue: 0.33, alpha: 1.0)
    }
}
