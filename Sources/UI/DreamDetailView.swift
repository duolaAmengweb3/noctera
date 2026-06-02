import SwiftUI
import SwiftData

/// A dream entry with the aurora reading card. Omen is free; the full reflection + AI + sharing are Pro.
struct DreamDetailView: View {
    @Bindable var dream: Dream
    @EnvironmentObject private var entitlement: EntitlementStore
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var allDreams: [Dream]

    @State private var editing = false
    @State private var showPaywall = false
    @State private var shareItem: ShareImage?

    private var pro: Bool { entitlement.isUnlocked }
    private var memory: String? { MemoryEngine.callback(for: dream, in: allDreams) }
    @State private var art: UIImage?
    @State private var artLoading = false

    var body: some View {
        ZStack {
            NocteraBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    titleBlock
                    transcriptSection
                    if !dream.symbols.isEmpty { symbolsSection }
                    if !dream.tags.isEmpty {
                        VStack(alignment: .leading, spacing: 11) {
                            SectionLabel(text: "Tags")
                            FlowChips(dream.tags)
                        }
                    }
                    interpretationSection
                    dreamArtSection
                    if let memory { patternSection(memory) }
                }
                .padding(.horizontal, 20).padding(.top, 14).padding(.bottom, 40)
            }.scrollIndicators(.hidden)
        }
        .preferredColorScheme(.dark)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { editing = true } label: { Image(systemName: "pencil") }.tint(Theme.teal).accessibilityIdentifier("editDream")
            }
        }
        .sheet(isPresented: $editing) { DreamEditorView(dream: dream).environmentObject(entitlement) }
        .sheet(isPresented: $showPaywall) { PaywallView().environmentObject(entitlement) }
        .sheet(item: $shareItem) { ActivityView(items: [$0.image]) }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(spacing: 8) {
                Circle().fill(Theme.teal).frame(width: 6, height: 6)
                Text(dream.date.formatted(.dateTime.month().day().hour().minute()).uppercased())
                    .font(.system(size: 10, weight: .bold)).tracking(2.3).foregroundStyle(Theme.textMid)
                if dream.isLucid {
                    Text("LUCID").font(.system(size: 9, weight: .heavy)).foregroundStyle(Theme.bg1)
                        .padding(.horizontal, 6).padding(.vertical, 2).background(Capsule().fill(Theme.aurora))
                }
            }
            Text(dream.displayTitle).font(.nocteraSerif(40)).foregroundStyle(Theme.textHi)
            HStack(spacing: 12) {
                Label(dream.mood.label, systemImage: dream.mood.icon).font(.system(size: 13)).foregroundStyle(Theme.textLow)
                if dream.lucidity > 0 {
                    Label("Lucidity \(dream.lucidity)/10", systemImage: "sparkles").font(.system(size: 13)).foregroundStyle(Theme.violet)
                }
            }
        }.padding(.top, 6)
    }

    private var transcriptSection: some View {
        VStack(alignment: .leading, spacing: 11) {
            SectionLabel(text: "Dream record")
            Text(dream.transcript.isEmpty ? "—" : dream.transcript)
                .font(.system(size: 16)).lineSpacing(6).foregroundStyle(Theme.textHi.opacity(0.92))
                .nocteraSurface(fill: Theme.card, padding: 18)
        }
    }

    private var symbolsSection: some View {
        VStack(alignment: .leading, spacing: 11) {
            SectionLabel(text: "Symbols")
            FlowChips(dream.symbols.map { SymbolEngine.label($0) })
        }
    }

    private var interpretationSection: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack {
                SectionLabel(text: "Noctera reading")
                Spacer()
                if dream.aiGenerated { Text("ON-DEVICE AI").font(.system(size: 9, weight: .bold)).tracking(1.7).foregroundStyle(Theme.teal) }
            }
            VStack(alignment: .leading, spacing: 0) {
                MoonPhaseMark(size: 46)
                Text("\u{201C}\(dream.omen)\u{201D}")
                    .font(.nocteraSerif(28)).lineSpacing(7).foregroundStyle(Theme.textHi)
                    .fixedSize(horizontal: false, vertical: true).padding(.top, 16)
                AuroraRule(width: 64).padding(.top, 22)

                if pro {
                    Text(dream.reflection).font(.system(size: 14)).lineSpacing(5).foregroundStyle(Theme.textMid).padding(.top, 18)
                    Button { share() } label: {
                        HStack(spacing: 7) { Image(systemName: "square.and.arrow.up"); Text("Share this reading") }
                            .font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.teal)
                    }.padding(.top, 20)
                } else {
                    Button { showPaywall = true } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "lock.fill").font(.caption)
                            Text("Unlock the full reading, AI insight & shareable card").font(.system(size: 13, weight: .semibold))
                        }.foregroundStyle(Theme.teal).frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Theme.inset))
                    }.padding(.top, 18)
                }
            }
            .nocteraSurface(fill: Theme.card, padding: 20, cornerRadius: 24, accentEdge: true)
        }
    }

    private var dreamArtSection: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack {
                SectionLabel(text: "Dream art")
                Spacer()
                if !pro {
                    Text("PRO").font(.system(size: 9, weight: .heavy)).foregroundStyle(Theme.bg1)
                        .padding(.horizontal, 5).padding(.vertical, 1).background(Theme.aurora, in: Capsule())
                }
            }
            ZStack {
                if let art {
                    Image(uiImage: art).resizable().aspectRatio(contentMode: .fill)
                        .frame(height: 220).clipShape(RoundedRectangle(cornerRadius: 20))
                } else {
                    RoundedRectangle(cornerRadius: 20).fill(Theme.aurora).opacity(0.5).frame(height: 220)
                        .overlay {
                            if artLoading { ProgressView().tint(.white) }
                            else {
                                VStack(spacing: 8) {
                                    Image(systemName: pro ? "wand.and.stars" : "lock.fill").font(.title).foregroundStyle(.white)
                                    Text(artPrompt)
                                        .font(.system(size: 13, weight: .medium)).foregroundStyle(.white).multilineTextAlignment(.center).padding(.horizontal)
                                }
                            }
                        }
                        .onTapGesture {
                            if !pro { showPaywall = true }
                            else if DreamArt.isSupported && !artLoading { makeArt() }
                        }
                }
            }
            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Theme.border, lineWidth: 0.8))
        }
    }
    private var artPrompt: String {
        if !pro { return "Turn this dream into art\nGenerated privately on your device" }
        return DreamArt.isSupported ? "Paint this dream" : "Dream art needs an Apple-Intelligence device"
    }
    private func makeArt() {
        artLoading = true
        Task {
            let img = await DreamArt.generate(forDream: dream.transcript, symbols: dream.symbols)
            await MainActor.run { art = img; artLoading = false }
        }
    }

    private func patternSection(_ note: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(Theme.inset).frame(width: 46, height: 46)
                Image(systemName: "arrow.triangle.2.circlepath").font(.system(size: 16)).foregroundStyle(Theme.violet)
            }
            Text(note).font(.system(size: 14)).foregroundStyle(Theme.textHi)
            Spacer()
        }.nocteraSurface(fill: Theme.card, padding: 16)
    }

    private func share() {
        let oracle = OracleLines.line(forSymbol: dream.symbols.first, seed: InterpretationEngine.stableHash(dream.transcript))
        if let img = CardRenderer.image(omen: oracle, title: dream.displayTitle, square: false) {
            shareItem = ShareImage(image: img)
        }
    }
}

/// Simple wrapping chip row.
struct FlowChips: View {
    let items: [String]
    init(_ items: [String]) { self.items = items }
    var body: some View {
        HStack(spacing: 8) {
            ForEach(items.prefix(5), id: \.self) { s in
                Text(s).font(.system(size: 12, weight: .medium)).foregroundStyle(Theme.textMid)
                    .padding(.horizontal, 11).padding(.vertical, 8)
                    .background(Capsule().fill(Theme.inset))
                    .overlay(Capsule().strokeBorder(Theme.borderSoft, lineWidth: 0.7))
            }
        }
    }
}
