import Foundation
import SwiftData
import UIKit

/// Codable backup record (round-trips through backup/restore).
struct DreamBackup: Codable {
    var date: Date; var title: String; var transcript: String
    var symbols: [String]; var tags: [String]; var mood: String; var isLucid: Bool
    var omen: String; var reflection: String; var aiGenerated: Bool
}

/// Local export of all dreams — data ownership (directly answers the competitor "couldn't transfer my data" rage).
enum Exporter {
    private static func iso(_ d: Date) -> String {
        let f = ISO8601DateFormatter(); f.formatOptions = [.withFullDate]; return f.string(from: d)
    }
    private static func esc(_ v: String) -> String { "\"" + v.replacingOccurrences(of: "\"", with: "\"\"") + "\"" }

    static func csv(_ dreams: [Dream]) -> URL {
        var rows = ["Date,Title,Mood,Lucid,Symbols,Omen,Transcript"]
        for d in dreams.sorted(by: { $0.date > $1.date }) {
            rows.append([iso(d.date), d.displayTitle, d.mood.label, d.isLucid ? "yes" : "no",
                         d.symbols.map { SymbolEngine.label($0) }.joined(separator: "; "), d.omen, d.transcript]
                        .map(esc).joined(separator: ","))
        }
        return write(rows.joined(separator: "\n"), "Noctera-dreams.csv")
    }

    static func json(_ dreams: [Dream]) -> URL {
        let arr = dreams.sorted { $0.date > $1.date }.map { d -> [String: Any] in
            ["date": iso(d.date), "title": d.displayTitle, "mood": d.mood.rawValue, "lucid": d.isLucid,
             "symbols": d.symbols, "omen": d.omen, "reflection": d.reflection, "transcript": d.transcript]
        }
        let data = (try? JSONSerialization.data(withJSONObject: arr, options: [.prettyPrinted, .sortedKeys])) ?? Data()
        return write(String(data: data, encoding: .utf8) ?? "[]", "Noctera-dreams.json")
    }

    static func book(_ dreams: [Dream]) -> URL {
        var out = "# My Dream Journal\n\n"
        for d in dreams.sorted(by: { $0.date > $1.date }) {
            out += "## \(d.displayTitle)\n_\(iso(d.date)) · \(d.mood.label)\(d.isLucid ? " · lucid" : "")_\n\n"
            out += d.transcript + "\n\n"
            if !d.omen.isEmpty { out += "> \(d.omen)\n\n" }
            out += "---\n\n"
        }
        return write(out, "Noctera-dream-book.md")
    }

    // MARK: PDF (a printable dream book)
    @MainActor
    static func pdf(_ dreams: [Dream]) -> URL {
        let pageW: CGFloat = 612, pageH: CGFloat = 792, margin: CGFloat = 54
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Noctera-dream-book.pdf")
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageW, height: pageH))
        let titleAttr: [NSAttributedString.Key: Any] = [.font: UIFont(name: "NewYork-Regular", size: 22) ?? UIFont.systemFont(ofSize: 22)]
        let metaAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 11), .foregroundColor: UIColor.gray]
        let bodyAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 13)]
        let omenAttr: [NSAttributedString.Key: Any] = [.font: UIFont(name: "NewYork-Italic", size: 15) ?? UIFont.italicSystemFont(ofSize: 15)]
        try? renderer.writePDF(to: url) { ctx in
            var y = margin
            func page() { ctx.beginPage(); y = margin }
            func draw(_ s: String, _ attr: [NSAttributedString.Key: Any], gap: CGFloat) {
                let str = NSAttributedString(string: s, attributes: attr)
                let bound = str.boundingRect(with: CGSize(width: pageW - margin*2, height: .greatestFiniteMagnitude),
                                             options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
                if y + bound.height > pageH - margin { page() }
                str.draw(with: CGRect(x: margin, y: y, width: pageW - margin*2, height: bound.height),
                         options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
                y += bound.height + gap
            }
            page()
            draw("My Dream Journal", titleAttr, gap: 18)
            for d in dreams.sorted(by: { $0.date > $1.date }) {
                draw(d.displayTitle, titleAttr, gap: 3)
                draw("\(iso(d.date)) · \(d.mood.label)\(d.isLucid ? " · lucid" : "")", metaAttr, gap: 8)
                draw(d.transcript, bodyAttr, gap: 8)
                if !d.omen.isEmpty { draw("“\(d.omen)”", omenAttr, gap: 18) }
            }
        }
        return url
    }

    // MARK: Backup / Restore (your data, portable)
    static func backup(_ dreams: [Dream]) -> URL {
        let recs = dreams.sorted { $0.date > $1.date }.map {
            DreamBackup(date: $0.date, title: $0.title, transcript: $0.transcript, symbols: $0.symbols, tags: $0.tags,
                        mood: $0.moodRaw, isLucid: $0.isLucid, omen: $0.omen, reflection: $0.reflection, aiGenerated: $0.aiGenerated)
        }
        let enc = JSONEncoder(); enc.outputFormatting = [.prettyPrinted]; enc.dateEncodingStrategy = .iso8601
        let data = (try? enc.encode(recs)) ?? Data()
        return write(String(data: data, encoding: .utf8) ?? "[]", "Noctera-backup.json")
    }

    /// Returns number of dreams restored (skips ones already present by date+title).
    @discardableResult
    static func restore(from url: URL, into context: ModelContext, existing: [Dream]) -> Int {
        let needsStop = url.startAccessingSecurityScopedResource()
        defer { if needsStop { url.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: url) else { return 0 }
        let dec = JSONDecoder(); dec.dateDecodingStrategy = .iso8601
        guard let recs = try? dec.decode([DreamBackup].self, from: data) else { return 0 }
        let have = Set(existing.map { "\($0.date.timeIntervalSince1970.rounded())|\($0.title)" })
        var n = 0
        for r in recs {
            let key = "\(r.date.timeIntervalSince1970.rounded())|\(r.title)"
            if have.contains(key) { continue }
            context.insert(Dream(date: r.date, title: r.title, transcript: r.transcript, symbols: r.symbols,
                                 mood: Mood(rawValue: r.mood) ?? .neutral, isLucid: r.isLucid,
                                 omen: r.omen, reflection: r.reflection, aiGenerated: r.aiGenerated, tags: r.tags))
            n += 1
        }
        try? context.save()
        return n
    }

    private static func write(_ s: String, _ name: String) -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        try? s.data(using: .utf8)?.write(to: url)
        return url
    }
}
