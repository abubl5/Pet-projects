import Foundation

struct BrewStep: Codable {
    let title: String
    let duration: Int
}

struct BrewRecipe: Codable {
    let id: String
    let name: String
    let method: String
    let summary: String
    let coffeeGrams: Int
    let waterMilliliters: Int
    let temperatureCelsius: Int
    let duration: Int
    let notes: [String]
    let steps: [BrewStep]
}

struct BrewSession: Codable {
    let id: UUID
    let recipeID: String
    let recipeName: String
    let brewedAt: Date
    let rating: Int
    let tastingNote: String
    let journalNote: String
}

extension BrewRecipe {
    static let samples: [BrewRecipe] = [
        BrewRecipe(
            id: "v60-citrus",
            name: "Цитрусовый V60",
            method: "V60",
            summary: "Яркий вкус с коротким блумом и двумя проливами",
            coffeeGrams: 18,
            waterMilliliters: 300,
            temperatureCelsius: 93,
            duration: 180,
            notes: ["цедра апельсина", "черный чай", "карамельное послевкусие"],
            steps: [
                BrewStep(title: "Блум 40 мл", duration: 30),
                BrewStep(title: "Пролив до 180 мл", duration: 60),
                BrewStep(title: "Финальный пролив до 300 мл", duration: 90)
            ]
        ),
        BrewRecipe(
            id: "aeropress-berry",
            name: "Ягодный AeroPress",
            method: "AeroPress",
            summary: "Сладкая чашка с нотами ягод",
            coffeeGrams: 16,
            waterMilliliters: 240,
            temperatureCelsius: 88,
            duration: 120,
            notes: ["ягоды", "какао", "шелковистое тело"],
            steps: [
                BrewStep(title: "Добавить кофе и 60 мл воды", duration: 20),
                BrewStep(title: "Перемешать и долить до 240 мл", duration: 40),
                BrewStep(title: "Медленно продавить", duration: 60)
            ]
        ),
        BrewRecipe(
            id: "chemex-floral",
            name: "Цветочный Chemex",
            method: "Chemex",
            summary: "Чайный профиль для мытого зерна",
            coffeeGrams: 30,
            waterMilliliters: 500,
            temperatureCelsius: 94,
            duration: 240,
            notes: ["жасмин", "мед", "мягкая кислотность"],
            steps: [
                BrewStep(title: "Промыть фильтр и сделать блум", duration: 45),
                BrewStep(title: "Основной пролив до 350 мл", duration: 90),
                BrewStep(title: "Финальный пролив до 500 мл", duration: 105)
            ]
        ),
        BrewRecipe(
            id: "frenchpress-nutty",
            name: "Ореховый French Press",
            method: "French Press",
            summary: "Насыщенная ореховая чашка для зерна средней обжарки",
            coffeeGrams: 22,
            waterMilliliters: 330,
            temperatureCelsius: 92,
            duration: 240,
            notes: ["фундук", "темный шоколад", "округлое тело"],
            steps: [
                BrewStep(title: "Залить всю воду", duration: 30),
                BrewStep(title: "Настаивать", duration: 180),
                BrewStep(title: "Сломать корку и опустить пресс", duration: 30)
            ]
        )
    ]
}
