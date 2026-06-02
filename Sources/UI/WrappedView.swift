import SwiftUI

/// "Dream Wrapped" — a private mythology chapter, computed on-device from your dreams. Shareable cover.
struct WrappedView: View {
    let wrapped: Wrapped
    @Environment(\.dismiss) private var dismiss
    @State private var shareItem: ShareImage?

    var body: some View {
        ZStack {
            NocteraBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("DREAM WRAPPED").font(.system(size: 11, weight: .bold)).tracking(2.6).foregroundStyle(Theme.teal)
                        Text(wrapped.title).font(.nocteraSerif(36)).foregroundStyle(Theme.textHi)
                    }
                    HStack(spacing: 14) {
                        stat("\(wrapped.dreamCount)", "dreams")
                        stat("\(wrapped.topArchetypes.count)", "archetypes")
                        stat("\(wrapped.lucidNights)", "lucid")
                    }
                    VStack(alignment: .leading, spacing: 14) {
                        Text("\u{201C}\(wrapped.coverOmen)\u{201D}").font(.nocteraSerif(26)).lineSpacing(6).foregroundStyle(Theme.textHi)
                            .fixedSize(horizontal: false, vertical: true)
                        AuroraRule(width: 64)
                        Text(wrapped.narrative).font(.system(size: 15)).lineSpacing(6).foregroundStyle(Theme.textMid)
                    }.nocteraSurface(fill: Theme.card, padding: 22, cornerRadius: 24, accentEdge: true)

                    if !wrapped.topArchetypes.isEmpty {
                        VStack(alignment: .leading, spacing: 11) {
                            SectionLabel(text: "Your archetypes this chapter")
                            ForEach(wrapped.topArchetypes, id: \.key) { a in
                                HStack {
                                    Circle().fill(Theme.aurora).frame(width: 7, height: 7)
                                    Text(SymbolEngine.label(a.key).capitalized).foregroundStyle(Theme.textHi)
                                    Spacer(); Text("\(a.count)×").foregroundStyle(Theme.teal).font(.system(size: 13, weight: .semibold))
                                }.font(.system(size: 15))
                            }
                        }.nocteraSurface(fill: Theme.card, padding: 18)
                    }

                    Button { shareWrapped() } label: {
                        HStack { Image(systemName: "square.and.arrow.up"); Text("Share my chapter") }
                            .font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.bg1)
                            .frame(maxWidth: .infinity).padding(.vertical, 14).background(Capsule().fill(Theme.ivory))
                    }.buttonStyle(.plain)
                }.padding(20)
            }.scrollContentBackground(.hidden)
            .overlay(alignment: .topTrailing) { Button { dismiss() } label: { Image(systemName: "xmark.circle.fill") }.tint(Theme.textMid).padding() }
        }
        .preferredColorScheme(.dark)
        .sheet(item: $shareItem) { ActivityView(items: [$0.image]) }
    }
    private func stat(_ v: String, _ l: String) -> some View {
        VStack(spacing: 3) { Text(v).font(.nocteraSerif(28)).foregroundStyle(Theme.textHi); Text(l).font(.system(size: 11)).foregroundStyle(Theme.textLow) }
            .frame(maxWidth: .infinity).nocteraSurface(fill: Theme.card, padding: 14)
    }
    private func shareWrapped() {
        if let img = CardRenderer.image(omen: wrapped.coverOmen, title: wrapped.title, square: true) {
            shareItem = ShareImage(image: img)
        }
    }
}
