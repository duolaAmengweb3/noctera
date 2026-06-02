import Foundation
import SwiftData

enum Mood: String, Codable, CaseIterable, Identifiable {
    case peaceful, vivid, anxious, joyful, sad, confusing, neutral
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var icon: String {
        switch self {
        case .peaceful: "leaf.fill"; case .vivid: "sparkles"; case .anxious: "wind"
        case .joyful: "sun.max.fill"; case .sad: "cloud.rain.fill"; case .confusing: "questionmark.circle.fill"; case .neutral: "circle"
        }
    }
}

@Model
final class Dream {
    var id: UUID
    var date: Date              // the night the dream occurred
    var title: String
    var transcript: String
    var symbolsRaw: [String]    // matched symbol keys
    var moodRaw: String
    var isLucid: Bool
    var lucidity: Int           // 0–10 lucidity/awareness spectrum (0 = not lucid)
    var omen: String            // cached interpretation (always present — dictionary or AI)
    var reflection: String
    var aiGenerated: Bool       // true if an on-device AI reading was used
    var tagsRaw: [String]       // manual tags: people / places / free-form
    var createdAt: Date

    init(date: Date = .now, title: String = "", transcript: String = "",
         symbols: [String] = [], mood: Mood = .neutral, isLucid: Bool = false, lucidity: Int = 0,
         omen: String = "", reflection: String = "", aiGenerated: Bool = false, tags: [String] = []) {
        self.id = UUID(); self.date = date; self.title = title; self.transcript = transcript
        self.symbolsRaw = symbols; self.moodRaw = mood.rawValue
        self.lucidity = lucidity; self.isLucid = isLucid || lucidity > 0
        self.omen = omen; self.reflection = reflection; self.aiGenerated = aiGenerated
        self.tagsRaw = tags; self.createdAt = .now
    }
    var tags: [String] { tagsRaw }

    var mood: Mood { Mood(rawValue: moodRaw) ?? .neutral }
    var symbols: [String] { symbolsRaw }
    var displayTitle: String { title.isEmpty ? "Untitled dream" : title }
}

@Model
final class AppSettings {
    var onboarded: Bool
    var realityCheckEnabled: Bool      // Pro: lucid-dream reality-check reminders
    var realityCheckHour: Int          // hour of day for reality-check ping
    var morningReminderEnabled: Bool   // gentle "capture last night's dream" reminder
    var morningReminderHour: Int
    var preferAI: Bool                 // use on-device AI reading when available
    var personalContext: String        // recurring people/symbols the AI should weave in
    var faceLockEnabled: Bool          // require Face ID / passcode to open
    var weeklyInsightEnabled: Bool     // weekly "Dream Constellation" recap + notification

    init(onboarded: Bool = false, realityCheckEnabled: Bool = false, realityCheckHour: Int = 15,
         morningReminderEnabled: Bool = false, morningReminderHour: Int = 8, preferAI: Bool = true,
         personalContext: String = "", faceLockEnabled: Bool = false, weeklyInsightEnabled: Bool = true) {
        self.onboarded = onboarded
        self.realityCheckEnabled = realityCheckEnabled; self.realityCheckHour = realityCheckHour
        self.morningReminderEnabled = morningReminderEnabled; self.morningReminderHour = morningReminderHour
        self.preferAI = preferAI; self.personalContext = personalContext
        self.faceLockEnabled = faceLockEnabled; self.weeklyInsightEnabled = weeklyInsightEnabled
    }
}
