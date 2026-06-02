import SwiftUI
import SwiftData

struct RootView: View {
    @EnvironmentObject private var entitlement: EntitlementStore
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Query private var settingsList: [AppSettings]
    @Query(sort: \Dream.date, order: .reverse) private var dreams: [Dream]

    @State private var tab = 0
    @State private var showCapture = false
    @State private var showPaywall = false
    @State private var locked = false

    private var settings: AppSettings? { settingsList.first }

    /// Deterministic screenshot route (detail / wrapped / capture) — handled by a child that @Query's its own data.
    private var routeArg: String {
        let a = ProcessInfo.processInfo.arguments
        if let i = a.firstIndex(of: "--screen"), i + 1 < a.count, ["detail", "wrapped", "capture"].contains(a[i+1]) { return a[i+1] }
        return ""
    }

    var body: some View {
        Group {
            if let s = settings, s.onboarded {
                if !routeArg.isEmpty {
                    ShotHost(route: routeArg, settings: s).environmentObject(entitlement)
                } else {
                    TabView(selection: $tab) {
                        JournalView(settings: s, showCapture: $showCapture)
                            .tabItem { Label("Journal", systemImage: "moon.stars") }.tag(0)
                        PatternsView()
                            .tabItem { Label("Patterns", systemImage: "chart.line.uptrend.xyaxis") }.tag(1)
                        SettingsView(settings: s)
                            .tabItem { Label("Settings", systemImage: "gearshape") }.tag(2)
                    }
                    .tint(Theme.teal)
                    .fullScreenCover(isPresented: $showCapture) { CaptureFlowView(settings: s).environmentObject(entitlement) }
                    .sheet(isPresented: $showPaywall) { PaywallView().environmentObject(entitlement) }
                    .onAppear { publishSnapshot() }
                    .onChange(of: dreams.count) { publishSnapshot() }
                }
            } else {
                OnboardingView { finish() }
            }
        }
        .overlay { if locked { lockView } }
        .task { bootstrap(); if settings?.faceLockEnabled == true { locked = true; await unlock() } }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                if SharedStore.pendingCapture, settings?.onboarded == true { SharedStore.pendingCapture = false; showCapture = true }
                if locked { Task { await unlock() } }
            } else if phase == .background, settings?.faceLockEnabled == true { locked = true }
        }
        .onOpenURL { url in if url.scheme == "noctera", settings?.onboarded == true { showCapture = true } }
        .preferredColorScheme(.dark)
    }

    private func bootstrap() {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("--reset") {
            try? context.delete(model: Dream.self); try? context.delete(model: AppSettings.self)
        }
        if args.contains("--screenshots") { seed() }
        else if settings == nil { context.insert(AppSettings()); try? context.save() }

        if let i = args.firstIndex(of: "--screen"), i + 1 < args.count {
            switch args[i+1] {
            case "patterns": tab = 1
            case "settings": tab = 2
            case "paywall": DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { showPaywall = true }
            default: break
            }
        }
    }

    private var lockView: some View {
        ZStack {
            NocteraBackground()
            VStack(spacing: 16) {
                Image(systemName: "moon.stars.fill").font(.system(size: 44)).foregroundStyle(Theme.teal)
                Text("Noctera").font(.nocteraSerif(32)).foregroundStyle(Theme.textHi)
                Text("Your dreams are private.").font(.system(size: 14)).foregroundStyle(Theme.textMid)
                Button { Task { await unlock() } } label: {
                    Label("Unlock", systemImage: "faceid").font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.bg1)
                        .padding(.horizontal, 24).padding(.vertical, 12).background(Capsule().fill(Theme.ivory))
                }.buttonStyle(.plain).padding(.top, 6)
            }
        }
    }
    private func unlock() async { if await BiometricLock.authenticate() { locked = false } }

    private func finish() {
        let s = settings ?? { let n = AppSettings(); context.insert(n); return n }()
        s.onboarded = true; try? context.save()
    }
    private func publishSnapshot() { SharedStore.save(PatternEngine.snapshot(dreams)) }

    /// Representative data for App Store screenshots (real symbol/interpretation math, never shipped).
    private func seed() {
        EntitlementStore.shared.setUnlocked(true)
        let s = settings ?? { let n = AppSettings(); context.insert(n); return n }()
        s.onboarded = true
        if dreams.isEmpty {
            let cal = Calendar.current
            func d(_ x: Int) -> Date { cal.date(byAdding: .day, value: -x, to: .now)! }
            let items: [(Int, String, Mood, Bool)] = [
                (0, "I was back in my old apartment but the hallway kept getting longer. Something was behind me on the stairs — I never turned around. Then it started to rain, indoors.", .anxious, false),
                (1, "I could fly over the city. Every time I doubted it I dropped, then I stopped doubting and soared.", .vivid, true),
                (2, "My teeth were falling out one by one and I kept trying to hide them so no one would see.", .anxious, false),
                (4, "Deep calm water, I was floating and a familiar voice told me it was okay to let go.", .peaceful, false),
                (6, "A door I'd never noticed in my house. Behind it, a room full of light.", .joyful, false),
            ]
            for (ago, text, mood, lucid) in items {
                let syms = SymbolEngine.extract(from: text)
                let r = InterpretationEngine.dictionaryReading(transcript: text, symbols: syms, mood: mood)
                context.insert(Dream(date: d(ago), title: InterpretationEngine.suggestedTitle(from: text, symbols: syms),
                                     transcript: text, symbols: syms, mood: mood, isLucid: lucid, lucidity: lucid ? 6 : 0,
                                     omen: r.omen, reflection: r.reflection, aiGenerated: false))
            }
        }
        try? context.save()
    }
}

/// Screenshot harness — its own @Query reactively renders the target screen once seeded data arrives.
struct ShotHost: View {
    let route: String
    let settings: AppSettings
    @EnvironmentObject private var entitlement: EntitlementStore
    @Query(sort: \Dream.date, order: .reverse) private var dreams: [Dream]

    var body: some View {
        switch route {
        case "capture":
            CaptureFlowView(settings: settings).environmentObject(entitlement)
        case "detail":
            if let d = dreams.first(where: { $0.symbols.contains("house") }) ?? dreams.first {
                NavigationStack { DreamDetailView(dream: d).environmentObject(entitlement) }
            } else { NocteraBackground() }
        case "wrapped":
            if let w = WrappedEngine.make(dreams, monthsBack: 1) ?? WrappedEngine.make(dreams, monthsBack: 12) {
                WrappedView(wrapped: w)
            } else { NocteraBackground() }
        default: NocteraBackground()
        }
    }
}
