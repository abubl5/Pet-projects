import Foundation

struct Habit: Identifiable, Codable {
    let id: UUID
    var name: String
    var completedDates: [Date]
    
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.completedDates = []
    }
    
    mutating func toggleToday() {
        let calendar = Calendar.current
        if let index = completedDates.firstIndex(where: { calendar.isDateInToday($0) }) {
            completedDates.remove(at: index)
        } else {
            completedDates.append(Date())
        }
    }
    
    func isCompletedToday() -> Bool {
        completedDates.contains { Calendar.current.isDateInToday($0) }
    }
    
    var totalCount: Int {
        completedDates.count
    }
}