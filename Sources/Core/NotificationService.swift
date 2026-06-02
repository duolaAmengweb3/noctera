import Foundation
import UserNotifications

/// Local notifications only. Morning capture nudge (free) + lucid reality-check pings (Pro). No server.
enum NotificationService {
    @discardableResult
    static func requestAuth() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }
    static func cancelAll() { UNUserNotificationCenter.current().removeAllPendingNotificationRequests() }

    private static func daily(_ id: String, _ title: String, _ body: String, hour: Int) {
        let c = UNMutableNotificationContent(); c.title = title; c.body = body; c.sound = .default
        var comps = DateComponents(); comps.hour = hour
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: id, content: c,
            trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)))
    }

    private static func weekly(_ id: String, _ title: String, _ body: String, weekday: Int, hour: Int) {
        let c = UNMutableNotificationContent(); c.title = title; c.body = body; c.sound = .default
        var comps = DateComponents(); comps.weekday = weekday; comps.hour = hour
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: id, content: c,
            trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)))
    }

    /// Reschedule based on settings. Reality-check is Pro-gated by the caller. `dreamSigns` = the user's
    /// most recurring symbols, woven into reality-check prompts (the dream-sign → lucidity flywheel).
    static func reschedule(settings: AppSettings, isPro: Bool, dreamSigns: [String] = []) {
        cancelAll()
        if settings.morningReminderEnabled {
            daily("morning", "Catch it before it fades", "Tap to record last night's dream — it's already slipping.", hour: settings.morningReminderHour)
        }
        if settings.weeklyInsightEnabled {
            weekly("weekly", "Your week in dreams", "A new dream insight is ready — see what your nights kept returning to.", weekday: 1, hour: 10)
        }
        if isPro, settings.realityCheckEnabled {
            let sign = dreamSigns.first.map { "You keep dreaming of \(SymbolEngine.label($0)) — is it here now? " } ?? ""
            daily("reality", "Are you dreaming?", "\(sign)Reality check: look at your hands, count your fingers.", hour: settings.realityCheckHour)
            daily("reality2", "Reality check", "Look around — does anything feel off? You might be dreaming.", hour: min(23, settings.realityCheckHour + 5))
        }
    }
}
