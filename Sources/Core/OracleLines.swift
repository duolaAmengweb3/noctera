import Foundation

/// Co-Star-grade "uncanny one-liner" for the shareable card — sharp, a little witty, screenshot-bait.
/// Deterministic per dream (same dream → same line). Keyed to the dominant symbol.
enum OracleLines {
    private static let byKey: [String: [String]] = [
        "chased":  ["Your subconscious filed a complaint. You skipped the meeting.", "Whatever's behind you already knows your name."],
        "falling": ["You let go in the dream. Take notes.", "Gravity is just a feeling you haven't questioned yet."],
        "flying":  ["Part of you already left the ground. The rest is catching up.", "You remembered you were never that heavy."],
        "water":   ["Your feelings are running the night shift.", "Still or stormy, the water is always you."],
        "teeth":   ["You're guarding a smile you're not sure of.", "Being seen scares you more than being wrong."],
        "stairs":  ["You're counting floors instead of climbing them.", "The climb was the message, not the landing."],
        "house":   ["An old room of you left the light on.", "You moved out. Part of you kept the keys."],
        "door":    ["A threshold is tired of waiting for you.", "You already know which door. That's the problem."],
        "death":   ["Something in you is composting, not dying.", "An ending cleared the table. Set it again."],
        "snake":   ["You called it a threat. It was a shedding.", "The thing you fear is also molting."],
        "test":    ["You're grading yourself on a test nobody assigned.", "Unprepared for a class you already passed."],
        "naked":   ["Being seen isn't the same as being unsafe.", "You showed up as yourself. The horror, apparently."],
        "lost":    ["You don't need the whole map to take one step.", "Lost is just somewhere you haven't named yet."],
        "car":     ["Ask who's actually steering.", "You're in the car. Check if you're driving."],
        "money":   ["You're pricing yourself in the wrong currency.", "The wallet was never the point."],
        "fire":    ["Something has to burn before it can keep you warm.", "You called it destruction. It was clearing."],
        "rain":    ["Let it fall. That's how it clears.", "The sky did the crying you postponed."],
    ]
    private static let generic = [
        "The dream kept you. Sit with what lingers.",
        "Not everything wants decoding. Some of it just wants witnessing.",
        "The feeling outlived the images. Follow the feeling.",
        "Your nights are saying it plainly. Your days aren't listening yet."
    ]

    static func line(forSymbol key: String?, seed: Int) -> String {
        if let key, let arr = byKey[key], !arr.isEmpty { return arr[seed % arr.count] }
        return generic[seed % generic.count]
    }
}
