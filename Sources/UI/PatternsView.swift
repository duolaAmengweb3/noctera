import SwiftUI
import SwiftData

/// Recurring symbols & themes over time. Streak/totals free; the deep breakdown is Pro.
struct PatternsView: View {
    @EnvironmentObject private var entitlement: EntitlementStore
    @Query(sort: \Dream.date, order: .reverse) private var dreams: [Dream]
    @State private var showPaywall = false
    @State private var wrapped: Wrapped?

    private var pro: Bool { entitlement.isUnlocked }
    private var weekly: WeeklyInsight? { InsightEngine.weekly(dreams) }
    private var symbolCounts: [(key: String, count: Int)] { PatternEngine.symbolCounts(dreams) }
    private var moodCounts: [(mood: Mood, count: Int)] { PatternEngine.moodCounts(dreams) }
    private var maxSym: Int { symbolCounts.first?.count ?? 1 }

    var body: some View {
        NavigationStack {
            ZStack {
                NocteraBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        headline
                        if dreams.isEmpty {
                            Text("Log a few dreams to see your patterns emerge.").font(.system(size: 14)).foregroundStyle(Theme.textMid).padding(.top, 30)
                        } else {
                            if let w = weekly { weeklyCard(w) }
                            if symbolCounts.count >= 2 { constellationCard }
                            wrappedButton
                            if pro { symbolsCard; moodCard } else { lockedCard }
                        }
                    }.padding(.horizontal, 18).padding(.top, 6).padding(.bottom, 40)
                }.scrollContentBackground(.hidden)
            }
            .navigationTitle("Patterns")
            .sheet(isPresented: $showPaywall) { PaywallView().environmentObject(entitlement) }
            .sheet(item: $wrapped) { WrappedView(wrapped: $0) }
        }.preferredColorScheme(.dark)
    }

    private func weeklyCard(_ w: WeeklyInsight) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) { Image(systemName: "sparkles").foregroundStyle(Theme.teal)
                Text("THIS WEEK").font(.system(size: 10, weight: .bold)).tracking(2).foregroundStyle(Theme.teal) }
            Text(w.observation).font(.nocteraSerif(20)).lineSpacing(4).foregroundStyle(Theme.textHi).fixedSize(horizontal: false, vertical: true)
            Text("\(w.dreamCount) dream\(w.dreamCount == 1 ? "" : "s") this week").font(.system(size: 12)).foregroundStyle(Theme.textLow)
        }.nocteraSurface(fill: Theme.card, padding: 18, cornerRadius: 22, accentEdge: true)
    }

    private var constellationCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: "Your symbol constellation")
            ConstellationView(counts: symbolCounts)
        }.nocteraSurface(fill: Theme.card, padding: 14)
    }

    private var wrappedButton: some View {
        Button {
            if pro { wrapped = WrappedEngine.make(dreams, monthsBack: 1) ?? WrappedEngine.make(dreams, monthsBack: 12) }
            else { showPaywall = true }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "sparkles.rectangle.stack.fill").font(.title3).foregroundStyle(Theme.teal).frame(width: 28)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Dream Wrapped").font(.subheadline.weight(.semibold)).foregroundStyle(Theme.textHi)
                    Text("Your month in dreams — a private mythology chapter").font(.caption).foregroundStyle(Theme.textMid)
                }
                Spacer(); Image(systemName: pro ? "chevron.right" : "lock.fill").foregroundStyle(Theme.textLow)
            }.nocteraSurface(fill: Theme.card, padding: 16)
        }.buttonStyle(.plain)
    }

    private var headline: some View {
        HStack(spacing: 16) {
            stat("\(PatternEngine.streak(dreams))", "night streak")
            stat("\(dreams.count)", "dreams")
            stat("\(symbolCounts.count)", "symbols")
        }
    }
    private func stat(_ v: String, _ l: String) -> some View {
        VStack(spacing: 3) {
            Text(v).font(.nocteraSerif(30)).foregroundStyle(Theme.textHi)
            Text(l).font(.system(size: 11)).foregroundStyle(Theme.textLow)
        }.frame(maxWidth: .infinity).nocteraSurface(fill: Theme.card, padding: 16)
    }

    private var symbolsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel(text: "Recurring symbols")
            ForEach(symbolCounts.prefix(7), id: \.key) { item in
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(SymbolEngine.label(item.key).capitalized).font(.system(size: 14)).foregroundStyle(Theme.textHi)
                        Spacer()
                        Text("\(item.count)×").font(.system(size: 13, weight: .semibold).monospacedDigit()).foregroundStyle(Theme.teal)
                    }
                    GeometryReader { g in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Theme.inset)
                            Capsule().fill(Theme.aurora).frame(width: g.size.width * CGFloat(item.count) / CGFloat(maxSym))
                        }
                    }.frame(height: 7)
                }
            }
        }.nocteraSurface(fill: Theme.card, padding: 18)
    }

    private var moodCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(text: "Mood of your nights")
            ForEach(moodCounts, id: \.mood) { item in
                HStack {
                    Label(item.mood.label, systemImage: item.mood.icon).font(.system(size: 14)).foregroundStyle(Theme.textHi)
                    Spacer()
                    Text("\(item.count)").font(.system(size: 13, weight: .semibold).monospacedDigit()).foregroundStyle(Theme.textMid)
                }
            }
        }.nocteraSurface(fill: Theme.card, padding: 18)
    }

    private var lockedCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "chart.line.uptrend.xyaxis").font(.largeTitle).foregroundStyle(Theme.teal)
            Text("See what your dreams repeat").font(.nocteraSerif(22)).foregroundStyle(Theme.textHi)
            Text("Unlock recurring-symbol tracking, theme trends and mood patterns over time.").font(.system(size: 14))
                .foregroundStyle(Theme.textMid).multilineTextAlignment(.center)
            Button { showPaywall = true } label: {
                Text("Unlock with Pro").font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.bg1)
                    .padding(.horizontal, 24).padding(.vertical, 13).background(Capsule().fill(Theme.ivory))
            }.buttonStyle(.plain).accessibilityIdentifier("patternsUnlock")
        }.frame(maxWidth: .infinity).padding(.vertical, 36).nocteraSurface(fill: Theme.card, padding: 20)
    }
}
