import Foundation

/// An archetypal dream symbol with a consistent reading. Curated (Jungian-leaning), on-device, no network.
struct DreamSymbol: Identifiable {
    let key: String          // canonical key stored on the Dream
    let label: String        // display
    let synonyms: [String]   // words that match it in a transcript
    let meaning: String      // the reflection sentence
    let omen: String         // a short "omen" fragment for the headline reading
    var id: String { key }
}

/// The Noctera symbol lexicon + extraction. Deterministic so the same dream always reads the same.
enum SymbolEngine {
    static let lexicon: [DreamSymbol] = [
        .init(key: "chased", label: "being chased", synonyms: ["chase","chased","chasing","running from","pursued","followed","escape"],
              meaning: "Pursuit dreams usually point to something avoided in waking life — a task, an emotion, or a part of yourself.",
              omen: "you're running from a part of yourself you've already outrun"),
        .init(key: "falling", label: "falling", synonyms: ["fall","falling","fell","plummet","dropping"],
              meaning: "Falling can mark a loss of control or a fear of letting go — sometimes the body's own release into sleep.",
              omen: "you can let go of the ledge you've been gripping"),
        .init(key: "flying", label: "flying", synonyms: ["fly","flying","flew","soaring","floating up"],
              meaning: "Flight often expresses a wish for freedom, perspective, or rising above a situation.",
              omen: "something in you is ready to rise above it"),
        .init(key: "water", label: "water", synonyms: ["water","ocean","sea","river","lake","flood","waves","drowning","rain"],
              meaning: "Water mirrors emotion — calm or turbulent depending on its state.",
              omen: "your feelings are asking to be felt, not managed"),
        .init(key: "teeth", label: "losing teeth", synonyms: ["teeth","tooth","losing teeth","teeth falling"],
              meaning: "Teeth dreams are tied to confidence, communication, and the fear of how others see you.",
              omen: "you're more afraid of being seen than of being wrong"),
        .init(key: "stairs", label: "stairs", synonyms: ["stairs","staircase","steps","climbing","ascending","descending"],
              meaning: "Stairs are transitions — progress upward, regression downward, or the effort between states.",
              omen: "the climb matters more than the floor you reach"),
        .init(key: "house", label: "a house", synonyms: ["house","home","apartment","rooms","building","my old"],
              meaning: "A house is the self; its rooms are parts of you, and old houses are the past you still inhabit.",
              omen: "an old room of yourself is asking to be reopened"),
        .init(key: "door", label: "a door", synonyms: ["door","doorway","gate","threshold","entrance","locked door"],
              meaning: "Doors are choices and thresholds — what you'll open, and what you keep shut.",
              omen: "a threshold is waiting for you to choose"),
        .init(key: "death", label: "death", synonyms: ["death","dying","dead","funeral","grave"],
              meaning: "Death in dreams is rarely literal — it usually signals an ending that clears space for something new.",
              omen: "an ending is making room for what's next"),
        .init(key: "baby", label: "a baby", synonyms: ["baby","infant","newborn","pregnant","birth"],
              meaning: "Babies represent new beginnings, vulnerability, and something you're nurturing into being.",
              omen: "something new in you is still tender"),
        .init(key: "snake", label: "a snake", synonyms: ["snake","serpent","snakes"],
              meaning: "Snakes are transformation and hidden knowledge — and sometimes a threat you sense but can't name.",
              omen: "a change you fear is also a shedding"),
        .init(key: "test", label: "an exam", synonyms: ["test","exam","unprepared","late for","forgot","didn't study"],
              meaning: "Exam dreams surface self-judgment and the fear of being measured and found wanting.",
              omen: "you're grading yourself by a test no one assigned"),
        .init(key: "naked", label: "being exposed", synonyms: ["naked","nude","exposed","undressed","embarrassed"],
              meaning: "Nakedness reflects vulnerability and the fear of being judged for who you really are.",
              omen: "being seen is not the same as being unsafe"),
        .init(key: "lost", label: "being lost", synonyms: ["lost","can't find","maze","searching","wandering"],
              meaning: "Getting lost mirrors uncertainty about direction or identity in waking life.",
              omen: "you don't need the whole map to take the next step"),
        .init(key: "car", label: "a car", synonyms: ["car","driving","brakes","crash","vehicle","wheel"],
              meaning: "A vehicle is your sense of control and direction — who's driving, and whether you can steer.",
              omen: "ask who's really steering your direction"),
        .init(key: "phone", label: "a phone", synonyms: ["phone","call","texting","no signal","can't dial"],
              meaning: "Phones point to connection — or a breakdown in communication you're worried about.",
              omen: "a conversation you're avoiding wants to happen"),
        .init(key: "money", label: "money", synonyms: ["money","cash","wallet","rich","poor","paying"],
              meaning: "Money reflects self-worth and energy as much as literal resources.",
              omen: "you're measuring your worth in the wrong currency"),
        .init(key: "fire", label: "fire", synonyms: ["fire","burning","flames","smoke"],
              meaning: "Fire is intensity — passion, anger, or a purification that destroys to renew.",
              omen: "something needs to burn down before it can warm you"),
        .init(key: "darkness", label: "darkness", synonyms: ["dark","darkness","shadow","night","can't see"],
              meaning: "Darkness is the unknown and the unconscious — not danger, but what hasn't been looked at yet.",
              omen: "the dark is unlit, not unsafe"),
        .init(key: "animal", label: "an animal", synonyms: ["dog","cat","horse","bird","wolf","bear","lion"],
              meaning: "Animals embody instinct and the parts of you that act before you think.",
              omen: "trust the instinct you keep talking yourself out of"),
        .init(key: "people", label: "a familiar face", synonyms: ["mother","father","friend","ex","partner","stranger","crowd"],
              meaning: "People in dreams often represent the traits in them that also live in you.",
              omen: "they're carrying a quality that's also yours"),
        .init(key: "rain", label: "rain", synonyms: ["rain","raining","storm","downpour","thunder"],
              meaning: "Rain washes and releases — grief, relief, or a feeling finally allowed to fall.",
              omen: "let it fall; that's how it clears"),
    ]

    private static let bySyn: [(String, DreamSymbol)] = lexicon.flatMap { sym in
        ([sym.label] + sym.synonyms).map { ($0.lowercased(), sym) }
    }

    /// Extract symbol keys present in a dream transcript, ordered by first appearance, deduped.
    static func extract(from text: String) -> [String] {
        let lower = " " + text.lowercased() + " "
        var found: [(Int, String)] = []
        var seen = Set<String>()
        for (syn, sym) in bySyn where !seen.contains(sym.key) {
            if let r = lower.range(of: syn), lower.distance(from: lower.startIndex, to: r.lowerBound) >= 0 {
                // word-ish boundary check to avoid matching inside larger words
                found.append((lower.distance(from: lower.startIndex, to: r.lowerBound), sym.key))
                seen.insert(sym.key)
            }
        }
        return found.sorted { $0.0 < $1.0 }.map { $0.1 }
    }

    static func symbol(_ key: String) -> DreamSymbol? { lexicon.first { $0.key == key } }
    static func label(_ key: String) -> String { symbol(key)?.label ?? key }
}
