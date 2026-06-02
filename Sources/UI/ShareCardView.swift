import SwiftUI

/// The shareable "omen" card — one focal serif line on aurora-night, exported to 9:16 / 1:1.
struct ShareCardView: View {
    let omen: String
    let title: String
    var square: Bool = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [Theme.bg0, Theme.bg1], startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [Theme.violet.opacity(0.30), Theme.teal.opacity(0.12), .clear],
                           center: .init(x: 0.7, y: 0.18), startRadius: 0, endRadius: 520).blur(radius: 30)
            Grain(opacity: 0.05)
            VStack(alignment: .leading, spacing: 26) {
                Spacer()
                MoonPhaseMark(size: 56)
                Text("\u{201C}\(omen)\u{201D}")
                    .font(.nocteraSerif(square ? 40 : 46))
                    .lineSpacing(square ? 8 : 12)
                    .foregroundStyle(Theme.textHi)
                    .fixedSize(horizontal: false, vertical: true)
                Capsule().fill(Theme.aurora).frame(width: 80, height: 3)
                Spacer()
                HStack(spacing: 8) {
                    Image(systemName: "sparkle").font(.system(size: 16)).foregroundStyle(Theme.teal)
                    Text("Noctera").font(.nocteraSerif(22, .medium)).foregroundStyle(Theme.textMid)
                    Spacer()
                    Text(title.uppercased()).font(.system(size: 12, weight: .bold)).tracking(2).foregroundStyle(Theme.textLow)
                }
            }
            .padding(square ? 56 : 70)
        }
        .frame(width: square ? 1080 : 1080, height: square ? 1080 : 1920)
    }
}

enum CardRenderer {
    @MainActor
    static func image(omen: String, title: String, square: Bool) -> UIImage? {
        let r = ImageRenderer(content: ShareCardView(omen: omen, title: title, square: square))
        r.scale = 1
        return r.uiImage
    }
}
