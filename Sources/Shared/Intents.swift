import AppIntents

/// "Log a dream" — runs from the Action Button, Siri, Shortcuts, or the Control Center control.
/// Opens Noctera straight into capture (the 3am hero entry).
struct LogDreamIntent: AppIntent {
    static var title: LocalizedStringResource = "Log a Dream"
    static var description = IntentDescription("Open Noctera and start capturing a dream.")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        SharedStore.pendingCapture = true
        return .result()
    }
}
