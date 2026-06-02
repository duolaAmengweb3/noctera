import Foundation

/// Snapshot shared with the widget via the App Group (no SwiftData dependency in the widget).
struct DreamSnapshot: Codable {
    var lastTitle: String?
    var lastOmen: String?
    var lastDate: Date?
    var streak: Int
    var topSymbol: String?
    var monthCount: Int
    var totalCount: Int
    var updatedAt: Date
}

enum SharedStore {
    static let groupID = "group.com.duolaameng.noctera"
    private static let key = "noctera.snapshot.v1"
    private static var defaults: UserDefaults? { UserDefaults(suiteName: groupID) }

    static func save(_ s: DreamSnapshot) {
        guard let d = defaults, let data = try? JSONEncoder().encode(s) else { return }
        d.set(data, forKey: key)
    }
    static func load() -> DreamSnapshot? {
        guard let d = defaults, let data = d.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(DreamSnapshot.self, from: data)
    }

    /// Cross-process flag: an intent (Action Button / Siri / Control Center) asked to start capture.
    static var pendingCapture: Bool {
        get { defaults?.bool(forKey: "noctera.pendingCapture") ?? false }
        set { defaults?.set(newValue, forKey: "noctera.pendingCapture") }
    }
}

/// Relative day phrasing reused by app + widget.
enum NightFormat {
    static func relative(_ date: Date?) -> String {
        guard let date else { return "—" }
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "today" }
        if cal.isDateInYesterday(date) { return "last night" }
        let d = cal.dateComponents([.day], from: date, to: .now).day ?? 0
        return d >= 0 ? "\(d) nights ago" : "—"
    }
}
