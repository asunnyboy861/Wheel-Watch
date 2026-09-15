import Foundation
import UserNotifications

extension Notification.Name {
    static let openRollRadar = Notification.Name("openRollRadar")
}

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        let content = response.notification.request.content
        guard content.categoryIdentifier == "ROLL_RADAR" else { return }
        let parts = content.title.split(separator: " ")
        if let symbol = parts.count > 1 ? String(parts[1]) : nil {
            UserDefaults.standard.set(symbol, forKey: "pendingRollSymbol")
            await MainActor.run {
                NotificationCenter.default.post(name: .openRollRadar, object: nil)
            }
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}

final class NotificationService {
    static let shared = NotificationService()
    private let center = UNUserNotificationCenter.current()

    static func requestAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func notify(symbol: String, severity: Severity, messages: [String]) {
        guard !MarketCalendar.isQuietHours else { return }
        let defaults = UserDefaults.standard
        let key = "lastNotified.\(symbol)"
        if let last = defaults.object(forKey: key) as? Date,
           Date().timeIntervalSince(last) < 300 { return }
        defaults.set(Date(), forKey: key)

        let content = UNMutableNotificationContent()
        switch severity {
        case .red:
            content.title = "🔴 \(symbol) — Act Now"
            content.interruptionLevel = .timeSensitive
        case .yellow:
            content.title = "🟡 \(symbol) — Worth a Look"
            content.interruptionLevel = .active
        case .green:
            content.title = "🟢 \(symbol) — Collecting"
            content.interruptionLevel = .passive
        }
        content.body = messages.prefix(3).joined(separator: "\n")
        content.body += "\n\nInformational only — not investment advice."
        content.sound = severity == .red ? .default : nil
        content.categoryIdentifier = "ROLL_RADAR"
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        center.add(request)
    }

    func notifyDigest(title: String, body: String) {
        guard !MarketCalendar.isQuietHours else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = nil
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        center.add(request)
    }

    func sendDailyReport(thetaTotal: Double, positionCount: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Daily wheel report"
        let plural = positionCount == 1 ? "" : "s"
        content.body = String(format: "Your %d position%@ collected about $%.2f in theta today. Nice rent.", positionCount, plural, thetaTotal)
        content.sound = nil
        let request = UNNotificationRequest(identifier: "daily-report", content: content, trigger: nil)
        center.add(request)
    }

    func sendOfflineNotice() {
        guard !MarketCalendar.isQuietHours else { return }
        let content = UNMutableNotificationContent()
        content.title = "Wheel Watch data sources offline"
        content.body = "Quotes could not be refreshed. The app will retry automatically — your positions are safe on this device."
        content.sound = nil
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        center.add(request)
    }

    func registerCategories() {
        let openAction = UNNotificationAction(identifier: "OPEN_ROLL_RADAR",
                                              title: "Open Roll Radar",
                                              options: [.foreground])
        let category = UNNotificationCategory(identifier: "ROLL_RADAR",
                                              actions: [openAction],
                                              intentIdentifiers: [])
        center.setNotificationCategories([category])
    }
}
