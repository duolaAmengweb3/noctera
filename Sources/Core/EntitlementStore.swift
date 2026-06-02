import Foundation
import StoreKit

/// One-time "Noctera Pro" unlock. StoreKit 2, on-device, no server.
@MainActor
final class EntitlementStore: ObservableObject {
    static let shared = EntitlementStore()
    static let productID = "com.duolaameng.noctera.pro"

    @Published private(set) var isUnlocked = false
    @Published private(set) var product: Product?

    private init() {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("--uitestPro") || args.contains("--screenshots") { isUnlocked = true }
        Task { await observeTransactions() }
        if !args.contains("--reset") { Task { await refresh() } }
    }

    var displayPrice: String { product?.displayPrice ?? "$4.99" }

    func loadProduct() async { product = try? await Product.products(for: [Self.productID]).first }

    func refresh() async {
        for await r in Transaction.currentEntitlements {
            if case .verified(let t) = r, t.productID == Self.productID { setUnlocked(true); return }
        }
    }
    private func observeTransactions() async {
        for await r in Transaction.updates {
            if case .verified(let t) = r, await t.productID == Self.productID { setUnlocked(true); await t.finish() }
        }
    }

    @discardableResult
    func purchase() async throws -> Bool {
        var p = product
        if p == nil { p = try await Product.products(for: [Self.productID]).first }
        guard let p else { return false }
        let result = try await p.purchase()
        switch result {
        case .success(let v):
            if case .verified(let t) = v { setUnlocked(true); await t.finish(); return true }
            return false
        default: return false
        }
    }

    func restore() async throws { try await AppStore.sync(); await refresh() }
    func setUnlocked(_ v: Bool) { isUnlocked = v }
}
