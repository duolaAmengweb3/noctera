import Foundation

/// "It remembers you" — longitudinal, cross-entry intelligence over the dreamer's own corpus.
/// All deterministic + on-device. The single biggest value lever (Rosebud's retention moat, ported to dreams).
enum MemoryEngine {

    /// A "this has visited you before" callback for a dream's dominant symbol.
    static func callback(for dream: Dream, in all: [Dream]) -> String? {
        guard let key = dream.symbols.first else { return nil }
        let priors = all.filter { $0.id != dream.id && $0.symbols.contains(key) }
        let n = priors.count + 1
        guard n >= 2 else { return nil }
        let label = SymbolEngine.label(key).capitalized
        var s = "\(label) has visited you \(n) times."
        // most common mood among the prior occurrences
        if let grouped = Dictionary(grouping: priors, by: { $0.mood }).max(by: { $0.value.count < $1.value.count }),
           grouped.value.count >= 2 {
            s += " Often when your nights feel \(grouped.key.label.lowercased())."
        }
        return s
    }
}

struct WeeklyInsight {
    let dreamCount: Int
    let topSymbol: String?
    let moods: [(mood: Mood, count: Int)]
    let observation: String
}

enum InsightEngine {
    static func weekly(_ all: [Dream], now: Date = .now) -> WeeklyInsight? {
        let weekAgo = now.addingTimeInterval(-7 * 86400)
        let recent = all.filter { $0.date >= weekAgo }
        guard !recent.isEmpty else { return nil }
        let top = PatternEngine.topSymbol(recent)
        let moods = PatternEngine.moodCounts(recent)
        return WeeklyInsight(dreamCount: recent.count, topSymbol: top, moods: moods,
                             observation: observation(recent, top: top))
    }

    private static func observation(_ recent: [Dream], top: String?) -> String {
        if let top, let sym = SymbolEngine.symbol(top) {
            let n = recent.filter { $0.symbols.contains(top) }.count
            if n >= 2 { return "\(sym.label.capitalized) ran through \(n) of your nights this week. \(sym.omen.prefix(1).uppercased() + sym.omen.dropFirst())." }
        }
        if let mood = PatternEngine.moodCounts(recent).first?.mood {
            return "Your week of dreams leaned \(mood.label.lowercased()). Worth noticing what your days were doing."
        }
        return "A quiet week of dreaming. Even the still nights are part of the pattern."
    }
}

struct Wrapped: Identifiable {
    let id = UUID()
    let title: String
    let dreamCount: Int
    let topArchetypes: [(key: String, count: Int)]
    let lucidNights: Int
    let dominantMood: Mood?
    let coverOmen: String
    let narrative: String
}

/// "Dream Wrapped" — a private mythology chapter, computed entirely on-device.
enum WrappedEngine {
    static func make(_ all: [Dream], monthsBack: Int = 1, now: Date = .now) -> Wrapped? {
        let since = Calendar.current.date(byAdding: .month, value: -monthsBack, to: now) ?? now
        let dreams = all.filter { $0.date >= since }
        guard dreams.count >= 3 else { return nil }
        let arche = Array(PatternEngine.symbolCounts(dreams).prefix(3))
        let lucid = dreams.filter { $0.isLucid }.count
        let mood = PatternEngine.moodCounts(dreams).first?.mood
        let label = monthsBack >= 12 ? "Your Year in Dreams" : "Your Month in Dreams"
        let coverOmen = arche.first.flatMap { SymbolEngine.symbol($0.key)?.omen }.map { $0.prefix(1).uppercased() + $0.dropFirst() } ?? "The nights remember what the days forget."
        return Wrapped(title: label, dreamCount: dreams.count, topArchetypes: arche, lucidNights: lucid,
                       dominantMood: mood, coverOmen: coverOmen, narrative: narrate(arche, mood: mood, lucid: lucid, count: dreams.count))
    }

    private static func narrate(_ arche: [(key: String, count: Int)], mood: Mood?, lucid: Int, count: Int) -> String {
        var parts: [String] = []
        if let a = arche.first { parts.append("This season your dreams returned again and again to \(SymbolEngine.label(a.key)).") }
        if arche.count >= 2 { parts.append("\(SymbolEngine.label(arche[1].key).capitalized) shadowed it.") }
        if let mood { parts.append("The mood that ruled your nights was \(mood.label.lowercased()).") }
        if lucid > 0 { parts.append("You woke up inside the dream \(lucid) time\(lucid == 1 ? "" : "s").") }
        parts.append("\(count) dreams, all kept — a private mythology only you have read.")
        return parts.joined(separator: " ")
    }
}
