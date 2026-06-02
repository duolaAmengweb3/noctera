import Foundation

enum PatternEngine {
    /// Consecutive days (ending today or yesterday) that have at least one dream.
    static func streak(_ dreams: [Dream], now: Date = .now) -> Int {
        let cal = Calendar.current
        let days = Set(dreams.map { cal.startOfDay(for: $0.date) })
        guard !days.isEmpty else { return 0 }
        var cursor = cal.startOfDay(for: now)
        if !days.contains(cursor) {
            cursor = cal.date(byAdding: .day, value: -1, to: cursor)!
            if !days.contains(cursor) { return 0 }
        }
        var count = 0
        while days.contains(cursor) {
            count += 1
            cursor = cal.date(byAdding: .day, value: -1, to: cursor)!
        }
        return count
    }

    /// Symbol keys with counts, most frequent first.
    static func symbolCounts(_ dreams: [Dream]) -> [(key: String, count: Int)] {
        var counts: [String: Int] = [:]
        for d in dreams { for s in d.symbols { counts[s, default: 0] += 1 } }
        return counts.map { (key: $0.key, count: $0.value) }.sorted { $0.count > $1.count }
    }

    static func topSymbol(_ dreams: [Dream]) -> String? { symbolCounts(dreams).first?.key }

    static func count(of symbol: String, thisMonth dreams: [Dream], now: Date = .now) -> Int {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: now)
        return dreams.filter {
            $0.symbols.contains(symbol) &&
            cal.dateComponents([.year, .month], from: $0.date) == comps
        }.count
    }

    static func recurrenceNote(for symbol: String, in dreams: [Dream], now: Date = .now) -> String? {
        let n = count(of: symbol, thisMonth: dreams, now: now)
        guard n >= 2 else { return nil }
        return "\(SymbolEngine.label(symbol).capitalized) has appeared \(n) times this month"
    }

    static func moodCounts(_ dreams: [Dream]) -> [(mood: Mood, count: Int)] {
        var counts: [Mood: Int] = [:]
        for d in dreams { counts[d.mood, default: 0] += 1 }
        return Mood.allCases.map { (mood: $0, count: counts[$0] ?? 0) }.filter { $0.count > 0 }.sorted { $0.count > $1.count }
    }

    static func snapshot(_ dreams: [Dream], now: Date = .now) -> DreamSnapshot {
        let sorted = dreams.sorted { $0.date > $1.date }
        let last = sorted.first
        let top = topSymbol(dreams)
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: now)
        let monthCount = dreams.filter { cal.dateComponents([.year, .month], from: $0.date) == comps }.count
        return DreamSnapshot(lastTitle: last?.displayTitle, lastOmen: last?.omen, lastDate: last?.date,
                             streak: streak(dreams, now: now), topSymbol: top.map { SymbolEngine.label($0) },
                             monthCount: monthCount, totalCount: dreams.count, updatedAt: now)
    }
}
