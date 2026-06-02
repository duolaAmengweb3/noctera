import SwiftUI

// MARK: - Noctera design language: editorial night, solid surfaces, no glass.

enum Theme {
    // Surfaces use restrained luminance steps. No translucent material layers.
    static let bg0 = Color(red: 0.027, green: 0.035, blue: 0.067)
    static let bg1 = Color(red: 0.018, green: 0.024, blue: 0.047)
    static let card = Color(red: 0.063, green: 0.082, blue: 0.137)
    static let raised = Color(red: 0.086, green: 0.110, blue: 0.176)
    static let inset = Color(red: 0.043, green: 0.055, blue: 0.094)

    static let teal = Color(red: 0.365, green: 0.835, blue: 0.780)
    static let violet = Color(red: 0.565, green: 0.510, blue: 0.918)
    static let indigo = Color(red: 0.314, green: 0.353, blue: 0.671)
    static let aurora = LinearGradient(
        colors: [teal, Color(red: 0.420, green: 0.720, blue: 0.835), violet],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let ivory = Color(red: 0.925, green: 0.914, blue: 0.878)
    static let textHi = ivory
    static let textMid = ivory.opacity(0.64)
    static let textLow = ivory.opacity(0.40)
    static let border = ivory.opacity(0.10)
    static let borderSoft = ivory.opacity(0.055)
}

extension Font {
    static func nocteraSerif(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
}

struct NocteraBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Theme.bg0, Theme.bg1], startPoint: .top, endPoint: .bottom)

            RadialGradient(
                colors: [Theme.indigo.opacity(0.23), .clear],
                center: .init(x: 0.82, y: -0.04),
                startRadius: 0,
                endRadius: 360
            )

            RadialGradient(
                colors: [Theme.teal.opacity(0.085), .clear],
                center: .init(x: 0.02, y: 0.32),
                startRadius: 0,
                endRadius: 280
            )

            Grain(opacity: 0.045)
        }
        .ignoresSafeArea()
    }
}

struct Grain: View {
    var opacity: Double = 0.045

    var body: some View {
        Canvas { context, size in
            var seed: UInt64 = 7919
            func random() -> Double {
                seed = seed &* 6364136223846793005 &+ 1442695040888963407
                return Double(seed >> 11) / Double(1 << 53)
            }

            for _ in 0..<Int(size.width * size.height / 650) {
                let point = CGRect(x: random() * size.width, y: random() * size.height, width: 1, height: 1)
                let tone = random() > 0.45 ? Color.white : Color.black
                context.fill(Path(point), with: .color(tone.opacity(random() * 0.45 + 0.15)))
            }
        }
        .opacity(opacity)
        .blendMode(.overlay)
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

struct Surface<Content: View>: View {
    var fill = Theme.card
    var padding: CGFloat = 18
    var cornerRadius: CGFloat = 22
    var accentEdge = false
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(fill)
            )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(accentEdge ? AnyShapeStyle(Theme.aurora) : AnyShapeStyle(Theme.border), lineWidth: accentEdge ? 1 : 0.7)
                    .opacity(accentEdge ? 0.62 : 1)
            }
    }
}

struct SectionLabel: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .bold))
            .tracking(2.3)
            .foregroundStyle(Theme.textLow)
    }
}

struct AuroraRule: View {
    var width: CGFloat = 54

    var body: some View {
        Capsule()
            .fill(Theme.aurora)
            .frame(width: width, height: 3)
    }
}

struct MoonPhaseMark: View {
    var size: CGFloat = 42

    var body: some View {
        ZStack {
            Circle()
                .fill(Theme.raised)
            Circle()
                .fill(Theme.ivory.opacity(0.88))
                .frame(width: size * 0.46, height: size * 0.46)
            Circle()
                .fill(Theme.raised)
                .frame(width: size * 0.46, height: size * 0.46)
                .offset(x: size * 0.11, y: -size * 0.03)
        }
        .frame(width: size, height: size)
        .overlay {
            Circle().strokeBorder(Theme.border, lineWidth: 0.8)
        }
    }
}

extension View {
    func nocteraSurface(
        fill: Color = Theme.card,
        padding: CGFloat = 18,
        cornerRadius: CGFloat = 22,
        accentEdge: Bool = false
    ) -> some View {
        Surface(fill: fill, padding: padding, cornerRadius: cornerRadius, accentEdge: accentEdge) { self }
    }
}
