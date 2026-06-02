import WidgetKit
import SwiftUI
import AppIntents

private let nightBG = Color(red: 0.039, green: 0.047, blue: 0.078)
private let nightBG2 = Color(red: 0.018, green: 0.024, blue: 0.047)
private let teal = Color(red: 0.365, green: 0.835, blue: 0.780)
private let ivory = Color(red: 0.925, green: 0.914, blue: 0.878)

struct NocteraEntry: TimelineEntry { let date: Date; let snapshot: DreamSnapshot? }

struct NocteraProvider: TimelineProvider {
    func placeholder(in c: Context) -> NocteraEntry {
        NocteraEntry(date: .now, snapshot: DreamSnapshot(lastTitle: "The endless hallway",
            lastOmen: "You're running from a part of yourself you've already outrun.",
            lastDate: .now, streak: 5, topSymbol: "chased", monthCount: 12, totalCount: 41, updatedAt: .now))
    }
    func getSnapshot(in c: Context, completion: @escaping (NocteraEntry) -> Void) {
        completion(NocteraEntry(date: .now, snapshot: SharedStore.load() ?? placeholder(in: c).snapshot))
    }
    func getTimeline(in c: Context, completion: @escaping (Timeline<NocteraEntry>) -> Void) {
        completion(Timeline(entries: [NocteraEntry(date: .now, snapshot: SharedStore.load())], policy: .after(.now.addingTimeInterval(3600))))
    }
}

struct NocteraWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: NocteraEntry
    private var s: DreamSnapshot? { entry.snapshot }

    var body: some View {
        switch family {
        case .accessoryInline:
            Text(s.map { "🌙 \($0.streak)-night streak" } ?? "Noctera")
        case .accessoryRectangular:
            Button(intent: LogDreamIntent()) {
                VStack(alignment: .leading, spacing: 2) {
                    Label("NOCTERA", systemImage: "moon.stars.fill").font(.caption2.weight(.bold))
                    Text(s?.lastOmen ?? "Tap to capture tonight's dream").font(.caption2).lineLimit(2)
                }
            }.buttonStyle(.plain)
        case .accessoryCircular:
            Button(intent: LogDreamIntent()) {
                ZStack { AccessoryWidgetBackground()
                    VStack(spacing: 0) { Image(systemName: "moon.stars.fill").font(.caption)
                        Text("\(s?.streak ?? 0)").font(.headline) } }
            }.buttonStyle(.plain)
        default: home.widgetURL(URL(string: "noctera://capture"))
        }
    }
    private var home: some View {
        ZStack {
            LinearGradient(colors: [nightBG, nightBG2], startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [teal.opacity(0.18), .clear], center: .topTrailing, startRadius: 0, endRadius: 120)
            VStack(alignment: .leading, spacing: 6) {
                HStack { Image(systemName: "moon.stars.fill"); Text("NOCTERA").font(.caption2.weight(.bold)).tracking(1.5); Spacer()
                    Text("\(s?.streak ?? 0)🌙").font(.caption2.weight(.bold)) }.foregroundStyle(teal)
                Spacer(minLength: 0)
                Text(s?.lastOmen ?? "Tap to capture last night's dream.")
                    .font(.system(.subheadline, design: .serif)).foregroundStyle(ivory).lineLimit(family == .systemMedium ? 3 : 4)
                if let t = s?.lastTitle { Text(t).font(.caption2).foregroundStyle(ivory.opacity(0.6)).lineLimit(1) }
            }.padding(14)
        }
    }
}

struct NocteraWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "NocteraWidget", provider: NocteraProvider()) { entry in
            NocteraWidgetView(entry: entry).containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Last Dream")
        .description("Your most recent reading and your streak.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

@available(iOS 18.0, *)
struct NocteraControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "NocteraCaptureControl") {
            ControlWidgetButton(action: LogDreamIntent()) {
                Label("Log a Dream", systemImage: "moon.stars.fill")
            }
        }
        .displayName("Capture a Dream")
        .description("Open Noctera and start recording.")
    }
}

@main
struct NocteraWidgetBundle: WidgetBundle {
    var body: some Widget {
        NocteraWidget()
        if #available(iOS 18.0, *) { NocteraControl() }
    }
}
