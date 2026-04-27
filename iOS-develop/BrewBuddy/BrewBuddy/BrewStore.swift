import Foundation

extension Notification.Name {
    static let brewStoreDidUpdate = Notification.Name("brewStoreDidUpdate")
}

final class BrewStore {
    static let shared = BrewStore()

    private let favoritesKey = "brewbuddy.favorite.ids"
    private let historyKey = "brewbuddy.session.history"
    private let defaults = UserDefaults.standard

    let recipes = BrewRecipe.samples

    private(set) var favoriteRecipeIDs: Set<String>
    private(set) var sessions: [BrewSession]

    private init() {
        let favoriteIDs = defaults.stringArray(forKey: favoritesKey) ?? []
        favoriteRecipeIDs = Set(favoriteIDs)

        if let data = defaults.data(forKey: historyKey),
           let decoded = try? JSONDecoder().decode([BrewSession].self, from: data) {
            sessions = decoded.sorted(by: { $0.brewedAt > $1.brewedAt })
        } else {
            sessions = []
        }
    }

    func recipe(withID id: String) -> BrewRecipe? {
        recipes.first(where: { $0.id == id })
    }

    func toggleFavorite(recipeID: String) {
        if favoriteRecipeIDs.contains(recipeID) {
            favoriteRecipeIDs.remove(recipeID)
        } else {
            favoriteRecipeIDs.insert(recipeID)
        }

        defaults.set(Array(favoriteRecipeIDs).sorted(), forKey: favoritesKey)
        NotificationCenter.default.post(name: .brewStoreDidUpdate, object: nil)
    }

    func isFavorite(recipeID: String) -> Bool {
        favoriteRecipeIDs.contains(recipeID)
    }

    func addSession(_ session: BrewSession) {
        sessions.insert(session, at: 0)
        persistSessions()
        NotificationCenter.default.post(name: .brewStoreDidUpdate, object: nil)
    }

    private func persistSessions() {
        guard let data = try? JSONEncoder().encode(sessions) else { return }
        defaults.set(data, forKey: historyKey)
    }
}
