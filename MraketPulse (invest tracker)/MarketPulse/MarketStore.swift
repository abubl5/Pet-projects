import Foundation

extension Notification.Name {
    static let marketStoreDidUpdate = Notification.Name("marketStoreDidUpdate")
}

final class MarketStore {
    static let shared = MarketStore()

    private let favoritesKey = "marketpulse.favorite.assets"
    private let defaults = UserDefaults.standard

    let assets = MarketAsset.samples
    let sectors = SectorSnapshot.samples

    private(set) var favoriteAssetIDs: Set<String>

    private init() {
        favoriteAssetIDs = Set(defaults.stringArray(forKey: favoritesKey) ?? [])
    }

    func asset(withID id: String) -> MarketAsset? {
        assets.first(where: { $0.id == id })
    }

    func toggleFavorite(id: String) {
        if favoriteAssetIDs.contains(id) {
            favoriteAssetIDs.remove(id)
        } else {
            favoriteAssetIDs.insert(id)
        }

        defaults.set(Array(favoriteAssetIDs).sorted(), forKey: favoritesKey)
        NotificationCenter.default.post(name: .marketStoreDidUpdate, object: nil)
    }

    func isFavorite(id: String) -> Bool {
        favoriteAssetIDs.contains(id)
    }
}
