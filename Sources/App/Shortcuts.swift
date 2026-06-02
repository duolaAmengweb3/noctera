import AppIntents

struct NocteraShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: LogDreamIntent(),
                    phrases: ["Log a dream in \(.applicationName)", "\(.applicationName) capture a dream"],
                    shortTitle: "Log a Dream", systemImageName: "moon.stars.fill")
    }
}
