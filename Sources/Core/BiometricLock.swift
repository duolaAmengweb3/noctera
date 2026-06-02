import Foundation
import LocalAuthentication

/// Face ID / Touch ID / passcode gate for the private journal. On-device, no account.
enum BiometricLock {
    static var isAvailable: Bool {
        var err: NSError?
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: &err)
    }
    static func authenticate(reason: String = "Unlock your dream journal") async -> Bool {
        let ctx = LAContext()
        ctx.localizedFallbackTitle = "Enter Passcode"
        return await withCheckedContinuation { c in
            var err: NSError?
            guard ctx.canEvaluatePolicy(.deviceOwnerAuthentication, error: &err) else { c.resume(returning: true); return }
            ctx.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { ok, _ in c.resume(returning: ok) }
        }
    }
}
