import SwiftUI
import SwiftData

/// Edit a saved dream — re-extracts symbols and refreshes the reading on save.
struct DreamEditorView: View {
    @Bindable var dream: Dream
    @EnvironmentObject private var entitlement: EntitlementStore
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var newTag = ""

    var body: some View {
        NavigationStack {
            ZStack {
                NocteraBackground()
                Form {
                    Section { TextField("Title", text: $dream.title) }.listRowBackground(Theme.card)
                    Section("Dream") {
                        TextEditor(text: $dream.transcript).frame(minHeight: 140).scrollContentBackground(.hidden)
                    }.listRowBackground(Theme.card)
                    Section("Mood") {
                        Picker("Mood", selection: Binding(get: { dream.mood }, set: { dream.moodRaw = $0.rawValue })) {
                            ForEach(Mood.allCases) { Label($0.label, systemImage: $0.icon).tag($0) }
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            HStack { Text("Lucidity"); Spacer(); Text(dream.lucidity == 0 ? "Not lucid" : "\(dream.lucidity)/10").foregroundStyle(Theme.teal) }
                            Slider(value: Binding(get: { Double(dream.lucidity) }, set: { dream.lucidity = Int($0); dream.isLucid = dream.lucidity > 0 }), in: 0...10, step: 1).tint(Theme.teal)
                        }
                        DatePicker("Night of", selection: $dream.date, displayedComponents: .date)
                    }.listRowBackground(Theme.card)

                    Section {
                        if !dream.tagsRaw.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(dream.tagsRaw, id: \.self) { tag in
                                        HStack(spacing: 5) {
                                            Text(tag).font(.system(size: 13))
                                            Button { dream.tagsRaw.removeAll { $0 == tag } } label: { Image(systemName: "xmark.circle.fill").font(.caption2) }
                                        }.foregroundStyle(Theme.textHi)
                                        .padding(.horizontal, 10).padding(.vertical, 6)
                                        .background(Capsule().fill(Theme.inset))
                                    }
                                }
                            }
                        }
                        HStack {
                            TextField("Add a person, place or tag", text: $newTag).onSubmit(addTag)
                            Button("Add", action: addTag).disabled(newTag.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    } header: { Text("Tags · people · places") }
                    .listRowBackground(Theme.card)
                    Section {
                        Button("Delete dream", role: .destructive) { context.delete(dream); try? context.save(); dismiss() }
                    }.listRowBackground(Theme.card)
                }.scrollContentBackground(.hidden).foregroundStyle(Theme.textHi).tint(Theme.teal)
            }
            .navigationTitle("Edit").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() }.tint(Theme.textMid) }
                ToolbarItem(placement: .topBarTrailing) { Button("Save") { save() }.tint(Theme.teal).fontWeight(.semibold) }
            }
        }.preferredColorScheme(.dark)
    }

    private func addTag() {
        let t = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty, !dream.tagsRaw.contains(t) else { newTag = ""; return }
        dream.tagsRaw.append(t); newTag = ""
    }

    private func save() {
        let t = dream.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        dream.symbolsRaw = SymbolEngine.extract(from: t)
        let base = InterpretationEngine.dictionaryReading(transcript: t, symbols: dream.symbolsRaw, mood: dream.mood)
        dream.omen = base.omen; dream.reflection = base.reflection; dream.aiGenerated = false
        if dream.title.trimmingCharacters(in: .whitespaces).isEmpty {
            dream.title = InterpretationEngine.suggestedTitle(from: t, symbols: dream.symbolsRaw)
        }
        try? context.save()
        dismiss()
    }
}
