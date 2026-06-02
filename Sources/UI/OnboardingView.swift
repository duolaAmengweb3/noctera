import SwiftUI

struct OnboardingView: View {
    let onDone: () -> Void
    var body: some View {
        ZStack {
            NocteraBackground()
            VStack(spacing: 22) {
                Spacer()
                AuroraOrb().frame(width: 200, height: 200)
                Text("Noctera").font(.nocteraSerif(44)).foregroundStyle(Theme.textHi)
                Text("Remember your dreams.\nUnderstand what they're saying.")
                    .font(.title3).foregroundStyle(Theme.textMid).multilineTextAlignment(.center)
                VStack(alignment: .leading, spacing: 14) {
                    row("mic.fill", "Capture in seconds", "Speak the moment you wake — it saves itself")
                    row("sparkles", "Read the symbols", "A consistent, archetypal reading — on-device, private")
                    row("arrow.triangle.2.circlepath", "It remembers you", "Connects tonight's dream to the symbols your nights keep repeating")
                }.padding(20).background(RoundedRectangle(cornerRadius: 22).fill(Theme.card))
                    .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(Theme.border, lineWidth: 0.7))
                Spacer()
                Button(action: onDone) {
                    Text("Begin").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 6)
                }.buttonStyle(.borderedProminent).controlSize(.large).tint(Theme.teal).foregroundStyle(Theme.bg1)
                .accessibilityIdentifier("getStarted")
                Text("Free to use. One-time Pro, no subscription.").font(.caption).foregroundStyle(Theme.textLow)
            }.padding(24)
        }.preferredColorScheme(.dark)
    }
    private func row(_ i: String, _ t: String, _ s: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: i).font(.title3).foregroundStyle(Theme.teal).frame(width: 30)
            VStack(alignment: .leading, spacing: 1) {
                Text(t).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.textHi)
                Text(s).font(.caption).foregroundStyle(Theme.textMid)
            }
            Spacer()
        }
    }
}
