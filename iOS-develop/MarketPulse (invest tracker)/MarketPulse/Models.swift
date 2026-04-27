import Foundation

enum AssetKind: String, CaseIterable {
    case all = "Все"
    case stock = "Акции"
    case etf = "ETF"
    case crypto = "Крипто"
}

struct MarketAsset {
    let id: String
    let ticker: String
    let name: String
    let kind: AssetKind
    let sector: String
    let price: Double
    let dayChangePercent: Double
    let monthlyChangePercent: Double
    let summary: String
    let thesis: [String]
    let risks: [String]
}

struct SectorSnapshot {
    let title: String
    let changePercent: Double
    let leaders: [String]
}

extension MarketAsset {
    static let samples: [MarketAsset] = [
        MarketAsset(
            id: "aapl",
            ticker: "AAPL",
            name: "Apple",
            kind: .stock,
            sector: "Big Tech",
            price: 212.40,
            dayChangePercent: 1.8,
            monthlyChangePercent: 6.2,
            summary: "Крупная технологическая компания по производству техники",
            thesis: ["сильный бренд", "высокая маржа сервисов", "устойчивый спрос на устройства"],
            risks: ["давление регуляторов", "зависимость от циклов обновления iPhone", "конкуренция в Китае"]
        ),
        MarketAsset(
            id: "msft",
            ticker: "MSFT",
            name: "Microsoft",
            kind: .stock,
            sector: "Cloud & AI",
            price: 468.10,
            dayChangePercent: 0.9,
            monthlyChangePercent: 7.4,
            summary: "Лидер корпоративного софта, облака и AI-инфраструктуры",
            thesis: ["диверсифицированная выручка", "сильная позиция в enterprise"],
            risks: ["высокая оценка", "замедление корпоративных бюджетов"]
        ),
        MarketAsset(
            id: "nvda",
            ticker: "NVDA",
            name: "NVIDIA",
            kind: .stock,
            sector: "Semiconductors",
            price: 119.35,
            dayChangePercent: 3.1,
            monthlyChangePercent: 11.8,
            summary: "Технологическая компания по производству графических процессоров",
            thesis: ["лидерство в GPU", "спрос со стороны AI", "высокие темпы роста выручки"],
            risks: ["волатильность", "зависимость от больших клиентов"]
        ),
        MarketAsset(
            id: "spy",
            ticker: "SPY",
            name: "S&P 500 ETF",
            kind: .etf,
            sector: "Index",
            price: 531.20,
            dayChangePercent: 0.6,
            monthlyChangePercent: 4.4,
            summary: "Широкий индексный фонд на крупнейшие компании США",
            thesis: ["диверсификация", "понятный инструмент для долгого горизонта", "низкий порог входа"],
            risks: ["рыночные просадки", "высокая доля мегакэпов", "общерыночная корреляция"]
        ),
        MarketAsset(
            id: "qqq",
            ticker: "QQQ",
            name: "NASDAQ 100 ETF",
            kind: .etf,
            sector: "Growth",
            price: 456.75,
            dayChangePercent: 1.4,
            monthlyChangePercent: 8.1,
            summary: "Фонд на крупные технологические и growth-компании Nasdaq",
            thesis: ["экспозиция на тех", "понятный набор лидеров рынка"],
            risks: ["концентрация в технологияческой области", "чувствительность к ставкам", "повышенная волатильность"]
        ),
        MarketAsset(
            id: "btc",
            ticker: "BTC",
            name: "Bitcoin",
            kind: .crypto,
            sector: "Digital Assets",
            price: 68420.00,
            dayChangePercent: -1.2,
            monthlyChangePercent: 9.7,
            summary: "Крупнейший цифровой актив с высокой волатильностью и сильным вниманием рынка",
            thesis: ["ограниченная эмиссия", "институциональный интерес", "высокая ликвидность"],
            risks: ["резкие просадки", "регуляторная неопределенность", "эмоциональный рынок"]
        )
    ]
}

extension SectorSnapshot {
    static let samples: [SectorSnapshot] = [
        SectorSnapshot(title: "Big Tech", changePercent: 2.1, leaders: ["AAPL", "MSFT", "GOOGL"]),
        SectorSnapshot(title: "Semiconductors", changePercent: 3.4, leaders: ["NVDA", "AMD", "AVGO"]),
        SectorSnapshot(title: "Cloud & AI", changePercent: 2.8, leaders: ["MSFT", "AMZN", "SNOW"]),
        SectorSnapshot(title: "Fintech", changePercent: -0.6, leaders: ["PYPL", "SQ", "COIN"]),
        SectorSnapshot(title: "Digital Assets", changePercent: 1.2, leaders: ["BTC", "ETH", "COIN"])
    ]
}
