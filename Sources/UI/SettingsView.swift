import SwiftUI
import SwiftData

struct SettingsView: View {
    @Bindable var settings: AppSettings
    @EnvironmentObject private var entitlement: EntitlementStore
    @Environment(\.modelContext) private var context
    @Query private var dreams: [Dream]

    @State private var showPaywall = false
    @State private var exportURL: URL?
    @State private var showImporter = false
    @State private var showProfile = false
    @State private var restoreMsg: String?
    private var pro: Bool { entitlement.isUnlocked }

    var body: some View {
        NavigationStack {
            ZStack {
                NocteraBackground()
                Form {
                    Section {
                        if pro { Label("Noctera Pro unlocked", systemImage: "checkmark.seal.fill").foregroundStyle(Theme.teal) }
                        else {
                            Button { showPaywall = true } label: { Label("Unlock Noctera Pro — \(entitlement.displayPrice)", systemImage: "sparkles") }
                                .accessibilityIdentifier("settingsUnlock")
                            Button("Restore Purchases") { Task { try? await entitlement.restore() } }.font(.subheadline)
                        }
                    }.listRowBackground(Theme.card)

                    Section("Reminders") {
                        Toggle("Morning capture reminder", isOn: $settings.morningReminderEnabled)
                        if settings.morningReminderEnabled {
                            Stepper("At \(settings.morningReminderHour):00", value: $settings.morningReminderHour, in: 5...11)
                        }
                        Toggle("Weekly dream insight", isOn: $settings.weeklyInsightEnabled)
                        proToggle("Lucid reality-check reminders", isOn: $settings.realityCheckEnabled)
                        if pro && settings.realityCheckEnabled {
                            Stepper("Around \(settings.realityCheckHour):00", value: $settings.realityCheckHour, in: 9...20)
                        }
                    }.listRowBackground(Theme.card)

                    Section {
                        Toggle(isOn: $settings.faceLockEnabled) { Label("Require Face ID / passcode", systemImage: "lock.fill") }
                    } header: { Text("Privacy") } footer: {
                        Text("Lock your dream journal behind Face ID. Everything stays on this device — no account, no cloud, ever.").font(.caption).foregroundStyle(Theme.textLow)
                    }.listRowBackground(Theme.card)

                    Section {
                        proRow("Export as PDF", systemImage: "doc.richtext") { exportURL = Exporter.pdf(dreams) }
                        if pro {
                            Button { exportURL = Exporter.csv(dreams) } label: { Label("Export CSV", systemImage: "tablecells") }
                            Button { exportURL = Exporter.json(dreams) } label: { Label("Export JSON", systemImage: "curlybraces") }
                            Button { exportURL = Exporter.book(dreams) } label: { Label("Export dream book", systemImage: "book") }
                            Button { exportURL = Exporter.backup(dreams) } label: { Label("Back up (all data)", systemImage: "arrow.up.doc") }
                            Button { showImporter = true } label: { Label("Restore from backup", systemImage: "arrow.down.doc") }
                        }
                    } header: { Text("Your data") } footer: {
                        Text(pro ? (restoreMsg ?? "Your dreams are yours — PDF, CSV, JSON, or a full backup you can restore on any device.")
                                 : "Export, back up & restore your dreams anywhere. Pro.").font(.caption).foregroundStyle(Theme.textLow)
                    }.listRowBackground(Theme.card)

                    Section {
                        proToggle("Personalized on-device AI", isOn: $settings.preferAI)
                        proRow("Dream profile (for AI context)", systemImage: "person.text.rectangle") { showProfile = true }
                    } header: { Text("Reading") } footer: {
                        Text("Tell Noctera your recurring people, places and symbols — your on-device AI weaves them into readings. Never leaves your phone.").font(.caption).foregroundStyle(Theme.textLow)
                    }.listRowBackground(Theme.card)

                    Section {
                        Label("Add the Noctera widget", systemImage: "rectangle.stack")
                        Label("Bind \u{201C}Log a Dream\u{201D} to the Action Button", systemImage: "button.programmable")
                        Label("\u{201C}Hey Siri, log a dream in Noctera\u{201D}", systemImage: "mic.circle")
                    } header: { Text("Quick capture") } footer: {
                        Text("Capture a dream without opening the app — add the widget from your Home Screen, assign the Action Button in iOS Settings, or just ask Siri.").font(.caption).foregroundStyle(Theme.textLow)
                    }.listRowBackground(Theme.card)

                    Section("About") {
                        Link(destination: URL(string: "https://duolaamengweb3.github.io/noctera/privacy.html")!) { Label("Privacy Policy", systemImage: "hand.raised") }
                        Link(destination: URL(string: "https://duolaamengweb3.github.io/noctera/support.html")!) { Label("Support", systemImage: "questionmark.circle") }
                        HStack { Text("Version"); Spacer(); Text("1.0").foregroundStyle(.secondary) }
                    }.listRowBackground(Theme.card)

                    Section { Text("Noctera is 100% on-device. No account, no cloud, no tracking. Your dreams never leave your phone.").font(.caption).foregroundStyle(Theme.textMid) }
                        .listRowBackground(Color.clear)
                }.scrollContentBackground(.hidden).foregroundStyle(Theme.textHi).tint(Theme.teal)
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) { PaywallView().environmentObject(entitlement) }
            .sheet(item: $exportURL) { ActivityView(items: [$0]) }
            .sheet(isPresented: $showProfile) { DreamProfileView(settings: settings) }
            .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json]) { result in
                if case .success(let url) = result {
                    let n = Exporter.restore(from: url, into: context, existing: dreams)
                    restoreMsg = "Restored \(n) dream\(n == 1 ? "" : "s")."
                }
            }
            .onChange(of: settings.morningReminderEnabled) { reschedule() }
            .onChange(of: settings.realityCheckEnabled) { reschedule() }
            .onChange(of: settings.weeklyInsightEnabled) { reschedule() }
        }.preferredColorScheme(.dark)
    }

    @ViewBuilder private func proToggle(_ title: String, isOn: Binding<Bool>) -> some View {
        if pro { Toggle(title, isOn: isOn) }
        else { Button { showPaywall = true } label: { proLabel(title) } }
    }
    @ViewBuilder private func proRow(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        if pro { Button(action: action) { Label(title, systemImage: systemImage) } }
        else { Button { showPaywall = true } label: { proLabel(title, systemImage: systemImage) } }
    }
    private func proLabel(_ title: String, systemImage: String? = nil) -> some View {
        HStack(spacing: 8) {
            if let systemImage { Image(systemName: systemImage) }
            Text(title)
            Text("PRO").font(.system(size: 9, weight: .heavy)).foregroundStyle(Theme.bg1)
                .padding(.horizontal, 5).padding(.vertical, 1).background(Theme.aurora, in: Capsule())
        }.foregroundStyle(Theme.textHi)
    }
    private func reschedule() {
        let signs = PatternEngine.symbolCounts(dreams).prefix(3).map { $0.key }
        Task {
            let want = settings.morningReminderEnabled || settings.weeklyInsightEnabled || (pro && settings.realityCheckEnabled)
            guard want, await NotificationService.requestAuth() else { NotificationService.cancelAll(); return }
            NotificationService.reschedule(settings: settings, isPro: pro, dreamSigns: Array(signs))
        }
    }
}

/// Personal context the on-device AI weaves into readings — stays on device.
struct DreamProfileView: View {
    @Bindable var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ZStack {
                NocteraBackground()
                Form {
                    Section {
                        TextEditor(text: $settings.personalContext).frame(minHeight: 160).scrollContentBackground(.hidden)
                    } header: { Text("Your recurring world") } footer: {
                        Text("e.g. \"My grandmother who passed, my old house in Leeds, I'm changing careers.\" The on-device AI uses this to make readings personal. It never leaves your phone.")
                            .font(.caption).foregroundStyle(Theme.textLow)
                    }.listRowBackground(Theme.card)
                }.scrollContentBackground(.hidden).foregroundStyle(Theme.textHi).tint(Theme.teal)
            }
            .navigationTitle("Dream Profile").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() }.tint(Theme.teal) } }
        }.preferredColorScheme(.dark)
    }
}
