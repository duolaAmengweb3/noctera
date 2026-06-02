import SwiftUI

/// Volumetric aurora voice orb — layered glow rings + sweeping comet arc + radial audio corona + breathing core.
struct AuroraOrb: View {
    private let barCount = 64

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            ZStack {
                ambientBloom(t)
                darkWell
                glowRing(t)
                crispRing(t)
                cometArc(t)
                radialWaveform(t)
                core(t)
            }
            .frame(width: 300, height: 300)
            .drawingGroup()
        }
    }

    private func ambientBloom(_ t: Double) -> some View {
        Circle()
            .fill(RadialGradient(colors: [Theme.violet.opacity(0.34), Theme.teal.opacity(0.12), .clear],
                                 center: .center, startRadius: 8, endRadius: 165))
            .frame(width: 300, height: 300).blur(radius: 28)
            .scaleEffect(1 + 0.045 * sin(t * 1.1))
    }
    private var darkWell: some View {
        Circle().fill(RadialGradient(colors: [Theme.bg1, Theme.bg0], center: .center, startRadius: 0, endRadius: 110))
            .frame(width: 212, height: 212).overlay { Circle().strokeBorder(Theme.border, lineWidth: 1) }
    }
    private func glowRing(_ t: Double) -> some View {
        Circle().stroke(AngularGradient(colors: [Theme.teal, Theme.violet, Theme.teal, Theme.violet, Theme.teal], center: .center),
                        style: StrokeStyle(lineWidth: 11, lineCap: .round))
            .frame(width: 210, height: 210).blur(radius: 13).opacity(0.75).rotationEffect(.degrees(t * 10))
    }
    private func crispRing(_ t: Double) -> some View {
        Circle().stroke(AngularGradient(colors: [Theme.teal, Theme.violet, Theme.teal, Theme.violet, Theme.teal], center: .center),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round))
            .frame(width: 210, height: 210).opacity(0.5).rotationEffect(.degrees(t * 10))
    }
    private func cometArc(_ t: Double) -> some View {
        Circle().trim(from: 0, to: 0.11)
            .stroke(LinearGradient(colors: [.clear, Theme.teal, Theme.violet], startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round))
            .frame(width: 210, height: 210).rotationEffect(.degrees(t * 62))
            .shadow(color: Theme.violet.opacity(0.6), radius: 6)
    }
    private func radialWaveform(_ t: Double) -> some View {
        ZStack {
            ForEach(0..<barCount, id: \.self) { i in
                let p = Double(i) / Double(barCount)
                let env = 0.45 + 0.55 * abs(sin(p * .pi * 3))
                let pulse = pow(abs(sin(t * 2.0 + Double(i) * 0.55)), 1.4)
                let h = 6 + 30 * env * pulse
                Capsule().fill(auroraColor(p)).frame(width: 2.4, height: h)
                    .offset(y: -74).rotationEffect(.degrees(p * 360))
                    .opacity(0.55 + 0.45 * pulse)
            }
        }
    }
    private func core(_ t: Double) -> some View {
        Circle().fill(RadialGradient(colors: [Theme.teal.opacity(0.55), Theme.violet.opacity(0.22), .clear],
                                     center: .center, startRadius: 0, endRadius: 50))
            .frame(width: 96, height: 96).blur(radius: 7).scaleEffect(1 + 0.09 * sin(t * 2.3))
    }
    private func auroraColor(_ p: Double) -> Color {
        let m = 0.5 + 0.5 * sin(p * .pi * 2)
        return Color(red: 0.365 + (0.565 - 0.365) * m, green: 0.835 + (0.510 - 0.835) * m, blue: 0.780 + (0.918 - 0.780) * m)
    }
}
