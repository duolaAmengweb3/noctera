import Foundation
import UIKit

/// On-device dream → illustration via Apple's ImageCreator (iOS 18.4+, Apple-Intelligence devices).
/// Free, no server, no per-image cost — so it never breaks the buyout model.
/// Returns nil where unavailable (older devices / simulator); callers fall back to the aurora card.
enum DreamArt {
    static var isSupported: Bool {
        #if canImport(ImagePlayground)
        if #available(iOS 18.4, *) { return true }
        #endif
        return false
    }

    static func generate(forDream transcript: String, symbols: [String]) async -> UIImage? {
        #if canImport(ImagePlayground)
        if #available(iOS 18.4, *) {
            return await _generate(prompt: prompt(transcript, symbols))
        }
        #endif
        return nil
    }

    private static func prompt(_ transcript: String, _ symbols: [String]) -> String {
        let syms = symbols.prefix(3).map { SymbolEngine.label($0) }.joined(separator: ", ")
        let base = transcript.split(separator: " ").prefix(30).joined(separator: " ")
        return "A dreamlike, surreal nocturnal scene. \(base). Motifs: \(syms). Soft aurora light, ethereal, painterly."
    }

    #if canImport(ImagePlayground)
    @available(iOS 18.4, *)
    private static func _generate(prompt: String) async -> UIImage? {
        do {
            let creator = try await ImageCreator()
            let images = creator.images(for: [.text(prompt)], style: .illustration, limit: 1)
            for try await image in images { return UIImage(cgImage: image.cgImage) }
        } catch { return nil }
        return nil
    }
    #endif
}

#if canImport(ImagePlayground)
import ImagePlayground
#endif
