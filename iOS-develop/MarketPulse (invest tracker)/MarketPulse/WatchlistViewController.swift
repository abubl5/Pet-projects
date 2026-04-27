import UIKit

final class WatchlistViewController: UIViewController {
    private let store = MarketStore.shared
    private var filteredAssets = MarketAsset.samples
    private let segmentedControl = UISegmentedControl(items: AssetKind.allCases.map(\.rawValue))

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 12, left: 0, bottom: 24, right: 0)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(AssetCell.self, forCellWithReuseIdentifier: AssetCell.reuseIdentifier)
        return collectionView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Активы"
        view.backgroundColor = UIColor(red: 0.95, green: 0.98, blue: 0.96, alpha: 1.0)
        navigationItem.largeTitleDisplayMode = .always

        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Поиск по тикеру или названию"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false

        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.addAction(UIAction { [weak self] _ in
            self?.applyFilters()
        }, for: .valueChanged)

        view.addSubview(segmentedControl)
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            collectionView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 12),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadFavorites),
            name: .marketStoreDidUpdate,
            object: nil
        )

        applyFilters()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func reloadFavorites() {
        collectionView.reloadData()
    }

    private func applyFilters() {
        let selectedKind = AssetKind.allCases[segmentedControl.selectedSegmentIndex]
        let query = navigationItem.searchController?.searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""

        filteredAssets = store.assets.filter { asset in
            let matchesKind = selectedKind == .all || asset.kind == selectedKind
            let matchesQuery = query.isEmpty
                || asset.ticker.lowercased().contains(query)
                || asset.name.lowercased().contains(query)
                || asset.sector.lowercased().contains(query)
            return matchesKind && matchesQuery
        }

        collectionView.reloadData()
    }
}

extension WatchlistViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        applyFilters()
    }
}

extension WatchlistViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        filteredAssets.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AssetCell.reuseIdentifier, for: indexPath) as! AssetCell
        cell.configure(with: filteredAssets[indexPath.item], isFavorite: store.isFavorite(id: filteredAssets[indexPath.item].id))
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        navigationController?.pushViewController(AssetDetailViewController(assetID: filteredAssets[indexPath.item].id), animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let availableWidth = collectionView.bounds.width - 12
        let width = floor(availableWidth / 2)
        return CGSize(width: width, height: 190)
    }
}
