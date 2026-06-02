import SwiftUI
import SwiftData

@main
struct NocteraApp: App {
    @StateObject private var entitlement = EntitlementStore.shared
    let container: ModelContainer

    init() {
        let args = ProcessInfo.processInfo.arguments
        let isUnitTest = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        let inMemory = args.contains("--reset") || args.contains("--screenshots") || isUnitTest
        let config = ModelConfiguration(isStoredInMemoryOnly: inMemory, groupContainer: .none)
        if let c = try? ModelContainer(for: Dream.self, AppSettings.self, configurations: config) {
            container = c
        } else {
            try? FileManager.default.removeItem(at: config.url)
            container = try! ModelContainer(for: Dream.self, AppSettings.self,
                                            configurations: ModelConfiguration(isStoredInMemoryOnly: inMemory, groupContainer: .none))
        }
    }

    var body: some Scene {
        WindowGroup { RootView().environmentObject(entitlement) }
            .modelContainer(container)
    }
}
