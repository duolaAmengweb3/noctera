import SwiftUI
import SwiftData

/// The capture flow: record (voice) or type → save → reading. Presented full-screen.
struct CaptureFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var entitlement: EntitlementStore
    @State private var path: [Dream] = []
    let settings: AppSettings

    var body: some View {
        NavigationStack(path: $path) {
            CaptureView(settings: settings) { dream in path.append(dream) }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button { dismiss() } label: { Image(systemName: "xmark") }.tint(Theme.textMid)
                    }
                }
                .navigationDestination(for: Dream.self) { d in
                    DreamDetailView(dream: d).environmentObject(entitlement)
                        .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Done") { dismiss() }.tint(Theme.teal) } }
                }
        }.preferredColorScheme(.dark)
    }
}

struct CaptureView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var entitlement: EntitlementStore
    @StateObject private var speech = SpeechCapture()
    let settings: AppSettings
    var onSaved: (Dream) -> Void

    enum Mode { case voice, typing }
    @State private var mode: Mode = .voice
    @State private var typed = ""
    @State private var mood: Mood = .neutral
    @State private var isLucid = false
    @State private var started = false

    private var text: String { mode == .voice ? speech.transcript : typed }
    private var canSave: Bool { !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        ZStack {
            NocteraBackground()
            VStack(spacing: 0) {
                topBar.padding(.horizontal, 22).padding(.top, 8)
                Spacer(minLength: 12)
                if mode == .voice { voiceState } else { typingState }
                Spacer(minLength: 12)
                Button { saveForgotten() } label: {
                    Text("I can't remember it →").font(.system(size: 13)).foregroundStyle(Theme.textLow)
                }.buttonStyle(.plain).accessibilityIdentifier("forgotDream").padding(.bottom, 8)
                moodPicker
                controls.padding(.horizontal, 22).padding(.bottom, 26).padding(.top, 14)
            }
        }
        .preferredColorScheme(.dark)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard !started else { return }; started = true
            if ProcessInfo.processInfo.arguments.contains("--uitest") { mode = .typing; return }
            if ProcessInfo.processInfo.arguments.contains("--screenshots") { mode = .voice; return } // show orb, no mic prompt
            await speech.requestAuth()
            if speech.authorized && speech.available { speech.start() } else { mode = .typing }
        }
        .onDisappear { speech.stop() }
    }

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("NOCTERA").font(.system(size: 10, weight: .bold)).tracking(3).foregroundStyle(Theme.textLow)
                Text(Date.now.formatted(.dateTime.hour().minute())).font(.nocteraSerif(17)).foregroundStyle(Theme.textMid)
            }
            Spacer()
            HStack(spacing: 7) {
                Circle().fill(Theme.teal).frame(width: 6, height: 6)
                Text("AUTO-SAVING").font(.system(size: 9, weight: .bold)).tracking(1.6).foregroundStyle(Theme.textMid)
            }.padding(.horizontal, 11).padding(.vertical, 8)
            .background(Capsule().fill(Theme.card)).overlay(Capsule().strokeBorder(Theme.borderSoft, lineWidth: 0.7))
        }
    }

    private var voiceState: some View {
        VStack(spacing: 16) {
            Text("CAPTURING A DREAM").font(.system(size: 10, weight: .bold)).tracking(2.6).foregroundStyle(Theme.teal)
            Text("Stay with it.").font(.nocteraSerif(34)).foregroundStyle(Theme.textHi)
            AuroraOrb().frame(width: 240, height: 240).padding(.top, 4)
            Text(speech.transcript.isEmpty ? "Speak naturally. Noctera saves as you go." : speech.transcript)
                .font(.system(size: speech.transcript.isEmpty ? 14 : 16)).lineSpacing(5)
                .foregroundStyle(speech.transcript.isEmpty ? Theme.textMid : Theme.textHi)
                .multilineTextAlignment(.center).frame(maxWidth: .infinity).padding(.horizontal, 28)
                .frame(minHeight: 60)
        }
    }

    private var typingState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("WRITE THE DREAM").font(.system(size: 10, weight: .bold)).tracking(2.6).foregroundStyle(Theme.teal)
            TextEditor(text: $typed)
                .font(.system(size: 16)).lineSpacing(5).scrollContentBackground(.hidden)
                .foregroundStyle(Theme.textHi).frame(minHeight: 200)
                .padding(12).background(RoundedRectangle(cornerRadius: 18).fill(Theme.card))
                .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Theme.border, lineWidth: 0.7))
                .overlay(alignment: .topLeading) {
                    if typed.isEmpty { Text("I was back in…").font(.system(size: 16)).foregroundStyle(Theme.textLow).padding(20).allowsHitTesting(false) }
                }
        }.padding(.horizontal, 22)
    }

    private var moodPicker: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Toggle(isOn: $isLucid) { Text("Lucid").font(.system(size: 12, weight: .medium)) }
                    .toggleStyle(.button).tint(Theme.violet).foregroundStyle(Theme.textMid)
                ForEach(Mood.allCases.prefix(5)) { m in
                    Button { mood = m } label: {
                        Image(systemName: m.icon).font(.system(size: 13))
                            .foregroundStyle(mood == m ? Theme.bg1 : Theme.textMid)
                            .frame(width: 34, height: 34)
                            .background(Circle().fill(mood == m ? AnyShapeStyle(Theme.aurora) : AnyShapeStyle(Theme.inset)))
                    }.buttonStyle(.plain)
                }
            }
        }.padding(.bottom, 4)
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button {
                if mode == .voice { speech.stop(); mode = .typing; typed = speech.transcript }
                else { mode = .voice; if speech.authorized { speech.start() } }
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: mode == .voice ? "keyboard" : "mic.fill").font(.system(size: 12))
                    Text(mode == .voice ? "Type instead" : "Voice").font(.system(size: 13, weight: .medium))
                }.foregroundStyle(Theme.textMid).padding(.horizontal, 16).padding(.vertical, 15)
                .background(Capsule().fill(Theme.inset)).overlay(Capsule().strokeBorder(Theme.borderSoft, lineWidth: 0.7))
            }.buttonStyle(.plain)

            Button { save() } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark").font(.system(size: 11, weight: .bold))
                    Text("Save dream").font(.system(size: 14, weight: .semibold))
                }.foregroundStyle(Theme.bg1).frame(maxWidth: .infinity).padding(.vertical, 15)
                .background(Capsule().fill(canSave ? AnyShapeStyle(Theme.ivory) : AnyShapeStyle(Theme.textLow)))
            }.buttonStyle(.plain).disabled(!canSave).accessibilityIdentifier("saveDream")
        }
    }

    /// Keep the morning habit alive even when the dream is gone (a top user request).
    private func saveForgotten() {
        let dream = Dream(date: .now, title: "Forgotten dream",
                          transcript: "I woke knowing I dreamt, but it slipped away before I could hold it.",
                          symbols: [], mood: .neutral,
                          omen: "Some nights only leave a feeling. That counts too.",
                          reflection: "Showing up is how recall grows — the dreams come back to those who keep the door open.")
        context.insert(dream); try? context.save(); onSaved(dream)
    }

    private func save() {
        speech.stop()
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        let symbols = SymbolEngine.extract(from: t)
        let base = InterpretationEngine.dictionaryReading(transcript: t, symbols: symbols, mood: mood)
        let dream = Dream(date: .now, title: InterpretationEngine.suggestedTitle(from: t, symbols: symbols),
                          transcript: t, symbols: symbols, mood: mood, isLucid: isLucid, lucidity: isLucid ? 6 : 0,
                          omen: base.omen, reflection: base.reflection, aiGenerated: false)
        context.insert(dream)
        try? context.save()
        onSaved(dream)
        // Upgrade to a personalized on-device AI reading (Pro), if available — additive.
        if entitlement.isUnlocked && settings.preferAI {
            Task {
                let full = await InterpretationEngine.reading(transcript: t, symbols: symbols, mood: mood, preferAI: true, personalContext: settings.personalContext)
                await MainActor.run {
                    dream.omen = full.omen; dream.reflection = full.reflection; dream.aiGenerated = full.aiGenerated
                    try? context.save()
                }
            }
        }
    }
}
