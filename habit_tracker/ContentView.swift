import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = HabitViewModel()
    @State private var newHabitName = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    TextField("Новая привычка", text: $newHabitName)
                        .textFieldStyle(.roundedBorder)
                    
                    Button("Добавить") {
                        viewModel.addHabit(name: newHabitName)
                        newHabitName = ""
                    }
                }
                .padding()
                
                List {
                    ForEach(viewModel.habits) { habit in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(habit.name)
                                    .font(.headline)
                                Text("Всего выполнено: \(habit.totalCount)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Button {
                                viewModel.toggleHabit(habit)
                            } label: {
                                Image(systemName: habit.isCompletedToday() ? "checkmark.circle.fill" : "circle")
                                    .font(.title2)
                                    .foregroundStyle(habit.isCompletedToday() ? .green : .gray)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete(perform: viewModel.deleteHabit)
                }
            }
            .navigationTitle("Habit Tracker")
        }
    }
}