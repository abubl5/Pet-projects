import Foundation

class HabitViewModel: ObservableObject {
    @Published var habits: [Habit] = []
    
    private let key = "habits_storage_key"
    
    init() {
        load()
    }
    
    func addHabit(name: String) {
        guard !name.isEmpty else { return }
        habits.append(Habit(name: name))
        save()
    }
    
    func deleteHabit(at offsets: IndexSet) {
        habits.remove(atOffsets: offsets)
        save()
    }
    
    func toggleHabit(_ habit: Habit) {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        habits[index].toggleToday()
        save()
    }
    
    private func save() {
        if let data = try? JSONEncoder().encode(habits) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([Habit].self, from: data) else { return }
        habits = decoded
    }
}