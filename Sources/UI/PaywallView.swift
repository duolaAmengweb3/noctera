import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var entitlement: EntitlementStore
    @Environment(\.dismiss) private var dismiss
    @State private var buying = false

    // Every perk maps to a real, shipped feature.
    private let perks: [(String, String, String)] = [
        ("text.book.closed.fill", "Full dream readings", "The complete reflection behind every omen, not just the headline"),
        ("sparkles", "Personalized on-device AI", "A reading shaped to your dream — private, never sent anywhere"),
        ("chart.line.uptrend.xyaxis", "Pattern insights", "Track recurring symbols, themes & moods over time"),
        ("square.and.arrow.up.fill", "Shareable cards", "Turn any reading into a card made to post"),
        ("moon.zzz.fill", "Lucid reality-checks", "Habit-building reminders to wake up inside your dreams"),
        ("arrow.down.doc.fill", "Export everything", "CSV, JSON or a dream book — your data, always yours")
    ]

    var body: some View {
        ZStack {
            NocteraBackground()
            ScrollView {
                VStack(spacing: 18) {
                    AuroraOrb().frame(width: 150, height: 150).padding(.top, 24)
                    Text("Noctera Pro").font(.nocteraSerif(34)).foregroundStyle(Theme.textHi)
                    Text("Pay once. Yours forever. No subscription.").font(.subheadline).foregroundStyle(Theme.textMid)
                    VStack(spacing: 16) {
                        ForEach(perks, id: \.0) { p in
                            HStack(spacing: 14) {
                                Image(systemName: p.0).font(.title3).foregroundStyle(Theme.teal).frame(width: 30)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(p.1).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.textHi)
                                    Text(p.2).font(.caption).foregroundStyle(Theme.textMid)
                                }
                                Spacer()
                            }
                        }
                    }.padding(20).background(RoundedRectangle(cornerRadius: 22).fill(Theme.card))
                        .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(Theme.border, lineWidth: 0.7))
                    Button {
                        buying = true
                        Task { _ = try? await entitlement.purchase(); buying = false; if entitlement.isUnlocked { dismiss() } }
                    } label: { Text(buying ? "…" : "Unlock for \(entitlement.displayPrice)").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 6) }
                        .buttonStyle(.borderedProminent).controlSize(.large).tint(Theme.teal).foregroundStyle(Theme.bg1)
                        .accessibilityIdentifier("purchasePro")
                    Button("Restore") { Task { try? await entitlement.restore(); if entitlement.isUnlocked { dismiss() } } }
                        .font(.footnote).tint(Theme.textMid)
                    Text("Capturing dreams is always free. No ads, no account, on-device.").font(.caption2).foregroundStyle(Theme.textLow).multilineTextAlignment(.center)
                }.padding(20)
            }
            .overlay(alignment: .topTrailing) { Button { dismiss() } label: { Image(systemName: "xmark.circle.fill") }.tint(Theme.textMid).padding() }
        }.preferredColorScheme(.dark)
    }
}
