import XCTest
import SwiftData
import StoreKitTest
@testable import Noctera

final class NocteraTests: XCTestCase {

    func testSymbolExtraction() {
        let keys = SymbolEngine.extract(from: "Something was chasing me up the stairs in my old house")
        XCTAssertTrue(keys.contains("chased"))
        XCTAssertTrue(keys.contains("stairs"))
        XCTAssertTrue(keys.contains("house"))
    }

    func testInterpretationIsConsistent() {
        let t = "I was being chased down endless stairs"
        let syms = SymbolEngine.extract(from: t)
        let a = InterpretationEngine.dictionaryReading(transcript: t, symbols: syms, mood: .anxious)
        let b = InterpretationEngine.dictionaryReading(transcript: t, symbols: syms, mood: .anxious)
        XCTAssertEqual(a.omen, b.omen, "Same dream must read the same — kills the 'different every time' complaint")
        XCTAssertFalse(a.omen.isEmpty)
        XCTAssertFalse(a.reflection.isEmpty)
    }

    func testEmptyDreamStillReads() {
        let r = InterpretationEngine.dictionaryReading(transcript: "mmm", symbols: [], mood: .neutral)
        XCTAssertFalse(r.omen.isEmpty)
    }

    func testSuggestedTitle() {
        let t = "there was a snake in the grass"
        let title = InterpretationEngine.suggestedTitle(from: t, symbols: SymbolEngine.extract(from: t))
        XCTAssertFalse(title.isEmpty)
    }

    func testStreakAndCounts() throws {
        let c = try ModelContainer(for: Dream.self, AppSettings.self,
                                   configurations: ModelConfiguration(isStoredInMemoryOnly: true, groupContainer: .none))
        let ctx = ModelContext(c)
        let cal = Calendar.current
        for ago in 0..<3 {
            ctx.insert(Dream(date: cal.date(byAdding: .day, value: -ago, to: .now)!, transcript: "chased", symbols: ["chased"]))
        }
        let dreams = try ctx.fetch(FetchDescriptor<Dream>())
        XCTAssertEqual(PatternEngine.streak(dreams), 3)
        XCTAssertEqual(PatternEngine.symbolCounts(dreams).first?.key, "chased")
        XCTAssertEqual(PatternEngine.snapshot(dreams).totalCount, 3)
    }

    @MainActor
    func testRealPurchaseUnlocksPro() async throws {
        let session = try SKTestSession(configurationFileNamed: "Noctera")
        session.disableDialogs = true
        session.clearTransactions()
        let store = EntitlementStore.shared
        await store.loadProduct()
        let ok = try await store.purchase()
        XCTAssertTrue(ok)
        XCTAssertTrue(store.isUnlocked)
    }

    private func makeContext() throws -> ModelContext {
        let c = try ModelContainer(for: Dream.self, AppSettings.self,
                                   configurations: ModelConfiguration(isStoredInMemoryOnly: true, groupContainer: .none))
        return ModelContext(c)
    }

    @MainActor
    func testBackupAndRestoreRoundTrip() throws {
        let ctx = try makeContext()
        ctx.insert(Dream(date: .now, title: "The Chase", transcript: "chased up the stairs",
                         symbols: ["chased", "stairs"], mood: .anxious, omen: "o", reflection: "r", tags: ["mom", "old house"]))
        let dreams = try ctx.fetch(FetchDescriptor<Dream>())
        let url = Exporter.backup(dreams)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))

        let ctx2 = try makeContext()
        let n = Exporter.restore(from: url, into: ctx2, existing: [])
        XCTAssertEqual(n, 1)
        let restored = try ctx2.fetch(FetchDescriptor<Dream>())
        XCTAssertEqual(restored.first?.title, "The Chase")
        XCTAssertEqual(restored.first?.tags, ["mom", "old house"])
        XCTAssertEqual(restored.first?.symbols, ["chased", "stairs"])
        // restoring again must dedupe (no duplicates)
        let again = Exporter.restore(from: url, into: ctx2, existing: restored)
        XCTAssertEqual(again, 0)
    }

    @MainActor
    func testPDFExportProducesRealFile() throws {
        let ctx = try makeContext()
        ctx.insert(Dream(date: .now, title: "The House", transcript: "my old house", symbols: ["house"], mood: .peaceful, omen: "home", reflection: "r"))
        let url = Exporter.pdf(try ctx.fetch(FetchDescriptor<Dream>()))
        XCTAssertEqual(url.pathExtension, "pdf")
        let data = try Data(contentsOf: url)
        XCTAssertGreaterThan(data.count, 800)               // a real PDF, not empty
        XCTAssertEqual(data.prefix(4), Data("%PDF".utf8))   // PDF magic bytes
    }

    @MainActor
    func testShareCardRendersImage() {
        let img = CardRenderer.image(omen: "You're running from a part of yourself you've outrun", title: "The Chase", square: false)
        XCTAssertNotNil(img)
        XCTAssertGreaterThan(img?.size.width ?? 0, 100)
        let sq = CardRenderer.image(omen: "Let it fall", title: "Rain", square: true)
        XCTAssertNotNil(sq)
    }

    @MainActor
    func testMemoryCallbackAcrossEntries() throws {
        let ctx = try makeContext()
        for _ in 0..<3 { ctx.insert(Dream(transcript: "being chased", symbols: ["chased"], mood: .anxious)) }
        let dreams = try ctx.fetch(FetchDescriptor<Dream>())
        let note = MemoryEngine.callback(for: dreams[0], in: dreams)
        XCTAssertNotNil(note)
        XCTAssertTrue(note?.contains("3 times") ?? false)
    }

    @MainActor
    func testWeeklyInsightAndWrapped() throws {
        let ctx = try makeContext()
        for _ in 0..<4 { ctx.insert(Dream(date: .now, transcript: "water everywhere", symbols: ["water"], mood: .peaceful)) }
        let dreams = try ctx.fetch(FetchDescriptor<Dream>())
        let w = InsightEngine.weekly(dreams)
        XCTAssertEqual(w?.dreamCount, 4)
        XCTAssertFalse(w?.observation.isEmpty ?? true)
        let wrapped = WrappedEngine.make(dreams, monthsBack: 1)
        XCTAssertNotNil(wrapped)
        XCTAssertEqual(wrapped?.dreamCount, 4)
        XCTAssertEqual(wrapped?.topArchetypes.first?.key, "water")
    }

    func testOracleLineDeterministic() {
        let a = OracleLines.line(forSymbol: "chased", seed: 5)
        let b = OracleLines.line(forSymbol: "chased", seed: 5)
        XCTAssertEqual(a, b)
        XCTAssertFalse(a.isEmpty)
        XCTAssertFalse(OracleLines.line(forSymbol: nil, seed: 1).isEmpty)
    }

    @MainActor
    func testCSVHasRowPerDream() throws {
        let ctx = try makeContext()
        for i in 0..<3 { ctx.insert(Dream(date: .now, title: "D\(i)", transcript: "t")) }
        let url = Exporter.csv(try ctx.fetch(FetchDescriptor<Dream>()))
        let csv = try String(contentsOf: url, encoding: .utf8)
        XCTAssertEqual(csv.split(separator: "\n").count, 4)  // header + 3
    }
}
