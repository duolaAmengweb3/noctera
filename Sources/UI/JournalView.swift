import SwiftUI
import SwiftData

/// The dream book — timeline of entries with search. Free.
struct JournalView: View {
    @Bindable var settings: AppSettings
    @EnvironmentObject private var entitlement: EntitlementStore
    @Environment(\.modelContext) private var context
    @Query(sort: \Dream.date, order: .reverse) private var dreams: [Dream]
    @Binding var showCapture: Bool

    @State private var search = ""
    @State private var mode = 0           // 0 list · 1 calendar
    @State private var selectedDay: Date?

    private func sameDay(_ a: Date, _ b: Date) -> Bool { Calendar.current.isDate(a, inSameDayAs: b) }
    private var onThisNight: Dream? {
        let cal = Calendar.current
        return dreams.first { let d = cal.dateComponents([.day], from: $0.date, to: .now).day ?? 0; return d >= 27 && d <= 33 }
    }
    private var dayDreams: [Dream] {
        guard let d = selectedDay else { return [] }
        return dreams.filter { sameDay($0.date, d) }
    }

    private var filtered: [Dream] {
        guard !search.isEmpty else { return dreams }
        let q = search.lowercased()
        return dreams.filter { $0.title.lowercased().contains(q) || $0.transcript.lowercased().contains(q)
            || $0.symbols.contains { SymbolEngine.label($0).lowercased().contains(q) } }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                NocteraBackground()
                if dreams.isEmpty { emptyState }
                else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 14) {
                            streakStrip
                            Picker("", selection: $mode) { Text("List").tag(0); Text("Calendar").tag(1) }
                                .pickerStyle(.segmented)
                            if mode == 0 {
                                if search.isEmpty, let otn = onThisNight {
                                    NavigationLink { DreamDetailView(dream: otn).environmentObject(entitlement) } label: { onThisNightCard(otn) }
                                        .buttonStyle(.plain)
                                }
                                ForEach(filtered) { d in
                                    NavigationLink { DreamDetailView(dream: d).environmentObject(entitlement) } label: { row(d) }
                                        .buttonStyle(.plain)
                                }
                            } else {
                                MonthCalendar(dreams: dreams, selected: $selectedDay)
                                if selectedDay != nil {
                                    if dayDreams.isEmpty {
                                        Text("No dream recorded that night.").font(.system(size: 13)).foregroundStyle(Theme.textLow).padding(.top, 4)
                                    } else {
                                        ForEach(dayDreams) { d in
                                            NavigationLink { DreamDetailView(dream: d).environmentObject(entitlement) } label: { row(d) }
                                                .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                        }.padding(.horizontal, 18).padding(.top, 6).padding(.bottom, 100)
                    }.scrollContentBackground(.hidden)
                    .searchable(text: $search, prompt: "Search dreams & symbols")
                }
            }
            .navigationTitle("Dream Journal")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showCapture = true } label: { Image(systemName: "plus.circle.fill").font(.title3) }
                        .tint(Theme.teal).accessibilityIdentifier("addDream")
                }
            }
            .overlay(alignment: .bottom) { captureButton }
        }.preferredColorScheme(.dark)
    }

    private var streakStrip: some View {
        let s = PatternEngine.streak(dreams)
        return HStack(spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "moon.stars.fill").foregroundStyle(Theme.teal)
                Text("\(s)").font(.nocteraSerif(24)).foregroundStyle(Theme.textHi)
                Text(s == 1 ? "night streak" : "night streak").font(.system(size: 13)).foregroundStyle(Theme.textMid)
            }
            Spacer()
            Text("\(dreams.count) dreams").font(.system(size: 13)).foregroundStyle(Theme.textLow)
        }.nocteraSurface(fill: Theme.card, padding: 16)
    }

    private func row(_ d: Dream) -> some View {
        HStack(spacing: 14) {
            MoonPhaseMark(size: 40)
            VStack(alignment: .leading, spacing: 4) {
                Text(d.displayTitle).font(.nocteraSerif(18)).foregroundStyle(Theme.textHi).lineLimit(1)
                Text(NightFormat.relative(d.date) + " · " + d.mood.label).font(.system(size: 12)).foregroundStyle(Theme.textLow)
            }
            Spacer()
            if d.isLucid { Image(systemName: "sparkles").font(.caption).foregroundStyle(Theme.violet) }
            Image(systemName: "chevron.right").font(.caption2).foregroundStyle(Theme.textLow)
        }.nocteraSurface(fill: Theme.card, padding: 14)
    }

    private func onThisNightCard(_ d: Dream) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 7) { Image(systemName: "clock.arrow.circlepath").foregroundStyle(Theme.violet)
                Text("ON THIS NIGHT · A MONTH AGO").font(.system(size: 10, weight: .bold)).tracking(1.6).foregroundStyle(Theme.textMid) }
            Text(d.displayTitle).font(.nocteraSerif(20)).foregroundStyle(Theme.textHi)
            Text("\u{201C}\(d.omen)\u{201D}").font(.system(size: 13)).italic().foregroundStyle(Theme.textMid).lineLimit(2)
        }.nocteraSurface(fill: Theme.card, padding: 16, cornerRadius: 22, accentEdge: true)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            AuroraOrb().frame(width: 200, height: 200)
            Text("Your dreams begin here").font(.nocteraSerif(26)).foregroundStyle(Theme.textHi)
            Text("Tap below the moment you wake.\nIt only takes your voice.").font(.system(size: 14))
                .foregroundStyle(Theme.textMid).multilineTextAlignment(.center)
            Button { showCapture = true } label: {
                Text("Capture a dream").font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.bg1)
                    .padding(.horizontal, 26).padding(.vertical, 14).background(Capsule().fill(Theme.ivory))
            }.buttonStyle(.plain).padding(.top, 6).accessibilityIdentifier("captureEmpty")
        }.padding(30)
    }

    private var captureButton: some View {
        Button { showCapture = true } label: {
            HStack(spacing: 9) {
                Image(systemName: "mic.fill").font(.system(size: 15))
                Text("Capture a dream").font(.system(size: 15, weight: .semibold))
            }.foregroundStyle(Theme.bg1).padding(.horizontal, 26).padding(.vertical, 15)
            .background(Capsule().fill(Theme.aurora)).shadow(color: Theme.violet.opacity(0.4), radius: 16, y: 6)
        }.buttonStyle(.plain).padding(.bottom, 18).opacity(dreams.isEmpty ? 0 : 1)
    }
}

/// A month grid; nights with a dream get an aurora dot. Tap a day to filter.
struct MonthCalendar: View {
    let dreams: [Dream]
    @Binding var selected: Date?
    private let cal = Calendar.current
    private let cols = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    private var monthStart: Date {
        cal.date(from: cal.dateComponents([.year, .month], from: .now)) ?? .now
    }
    private var days: [Date?] {
        let range = cal.range(of: .day, in: .month, for: monthStart) ?? 1..<2
        let leading = (cal.component(.weekday, from: monthStart) - cal.firstWeekday + 7) % 7
        var cells: [Date?] = Array(repeating: nil, count: leading)
        for d in range { cells.append(cal.date(byAdding: .day, value: d - 1, to: monthStart)) }
        return cells
    }
    private func hasDream(_ d: Date) -> Bool { dreams.contains { cal.isDate($0.date, inSameDayAs: d) } }

    var body: some View {
        VStack(spacing: 10) {
            Text(monthStart.formatted(.dateTime.month(.wide).year())).font(.nocteraSerif(18)).foregroundStyle(Theme.textHi)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier("calendarMonth")
            LazyVGrid(columns: cols, spacing: 8) {
                ForEach(["S","M","T","W","T","F","S"].indices, id: \.self) { i in
                    Text(["S","M","T","W","T","F","S"][i]).font(.system(size: 11, weight: .semibold)).foregroundStyle(Theme.textLow)
                }
                ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                    if let day {
                        let on = selected.map { cal.isDate($0, inSameDayAs: day) } ?? false
                        Button { selected = (on ? nil : day) } label: {
                            VStack(spacing: 3) {
                                Text("\(cal.component(.day, from: day))").font(.system(size: 14)).foregroundStyle(Theme.textHi)
                                Circle().fill(hasDream(day) ? AnyShapeStyle(Theme.aurora) : AnyShapeStyle(Color.clear)).frame(width: 5, height: 5)
                            }.frame(maxWidth: .infinity).padding(.vertical, 7)
                            .background(RoundedRectangle(cornerRadius: 10).fill(on ? Theme.inset : Color.clear))
                        }.buttonStyle(.plain)
                    } else { Color.clear.frame(height: 34) }
                }
            }
        }.nocteraSurface(fill: Theme.card, padding: 16)
    }
}
