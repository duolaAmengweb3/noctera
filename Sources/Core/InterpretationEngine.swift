import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

struct Interpretation {
    var omen: String
    var reflection: String
    var aiGenerated: Bool
}

/// Produces a dream reading. The dictionary engine is the universal, always-available core
/// (consistent for the same dream). On iOS 26 devices with Apple Intelligence, an on-device
/// model personalizes it — additive, never a network call, never required.
enum InterpretationEngine {

    // MARK: Universal dictionary reading (deterministic — same dream always reads the same)
    static func dictionaryReading(transcript: String, symbols: [String], mood: Mood) -> Interpretation {
        let syms = symbols.compactMap { SymbolEngine.symbol($0) }
        let seed = stableHash(transcript)
        let omen: String
        if let first = syms.first {
            omen = capitalize(first.omen) + "."
        } else {
            let generic = ["The dream is quiet, but it kept you. Sit with what lingers.",
                           "Not every night needs decoding — some only ask to be remembered.",
                           "What you can't name yet is still worth writing down.",
                           "The feeling outlasts the images. Follow the feeling."]
            omen = generic[seed % generic.count]
        }
        var parts: [String] = syms.prefix(3).map { $0.meaning }
        parts.append(moodLine(mood))
        return Interpretation(omen: omen, reflection: parts.joined(separator: " "), aiGenerated: false)
    }

    // MARK: Public entry — AI when available, dictionary otherwise (both complete)
    static func reading(transcript: String, symbols: [String], mood: Mood, preferAI: Bool, personalContext: String = "") async -> Interpretation {
        let base = dictionaryReading(transcript: transcript, symbols: symbols, mood: mood)
        #if canImport(FoundationModels)
        if preferAI, #available(iOS 26.0, *) {
            if let ai = await aiReading(transcript: transcript, symbols: symbols, mood: mood, personalContext: personalContext) { return ai }
        }
        #endif
        return base
    }

    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private static func aiReading(transcript: String, symbols: [String], mood: Mood, personalContext: String) async -> Interpretation? {
        let model = SystemLanguageModel.default
        guard case .available = model.availability else { return nil }
        let instructions = """
        You are a warm, literary dream-reflection guide — not a therapist or medical advisor. \
        Given a dream, respond with exactly two parts:
        Line 1: a single evocative "omen" sentence (under 20 words), symbolic and personal, no quotes.
        Then: a 2–3 sentence reflection connecting the symbols to the feeling. \
        Never give medical, clinical, or diagnostic advice. Keep it gentle and for self-reflection only.
        """
        var prompt = """
        Dream: \(transcript)
        Symbols noticed: \(symbols.map { SymbolEngine.label($0) }.joined(separator: ", "))
        Mood: \(mood.label)
        """
        let ctx = personalContext.trimmingCharacters(in: .whitespacesAndNewlines)
        if !ctx.isEmpty { prompt += "\nThe dreamer's recurring context (weave in only if relevant): \(ctx)" }
        do {
            let session = LanguageModelSession(instructions: instructions)
            let response = try await session.respond(to: prompt)
            let text = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { return nil }
            let lines = text.split(separator: "\n", omittingEmptySubsequences: true).map { String($0).trimmingCharacters(in: .whitespaces) }
            let omen = lines.first.map { $0.replacingOccurrences(of: "\"", with: "") } ?? text
            let reflection = lines.dropFirst().joined(separator: " ")
            return Interpretation(omen: omen, reflection: reflection.isEmpty ? dictionaryReading(transcript: transcript, symbols: symbols, mood: mood).reflection : reflection, aiGenerated: true)
        } catch {
            return nil
        }
    }
    #endif

    // MARK: helpers
    static func suggestedTitle(from transcript: String, symbols: [String]) -> String {
        if let first = symbols.first, let s = SymbolEngine.symbol(first) {
            return "The " + s.label.replacingOccurrences(of: "a ", with: "").replacingOccurrences(of: "an ", with: "").replacingOccurrences(of: "being ", with: "")
                .prefix(1).uppercased() + s.label.replacingOccurrences(of: "a ", with: "").replacingOccurrences(of: "an ", with: "").replacingOccurrences(of: "being ", with: "").dropFirst()
        }
        let words = transcript.split(separator: " ").prefix(4).joined(separator: " ")
        return words.isEmpty ? "Untitled dream" : String(words).capitalized
    }

    private static func moodLine(_ mood: Mood) -> String {
        switch mood {
        case .peaceful: "The calm you felt is worth carrying into the day."
        case .vivid: "Its vividness suggests something in you is wide awake, even at rest."
        case .anxious: "The unease is a signal, not a verdict — name it gently."
        case .joyful: "Hold the joy; dreams rarely lie about what delights you."
        case .sad: "The sadness asked to be felt while you were safe enough to feel it."
        case .confusing: "Confusion often means two true things are competing for room."
        case .neutral: "Even an ordinary night leaves a residue worth noticing."
        }
    }

    private static func capitalize(_ s: String) -> String { s.prefix(1).uppercased() + s.dropFirst() }
    static func stableHash(_ s: String) -> Int {
        var h: UInt64 = 1469598103934665603
        for b in s.utf8 { h = (h ^ UInt64(b)) &* 1099511628211 }
        return Int(h % 1_000_000)
    }
}
