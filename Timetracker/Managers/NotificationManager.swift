import Foundation
import UserNotifications

/// Stará se o systémové notifikace – konkrétně o připomínku po 2 hodinách
/// s tlačítky „Pokračovat“ a „Zastavit“.
@MainActor
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    static let categoryID = "TRACKING_REMINDER"
    static let continueID = "CONTINUE"
    static let stopID = "STOP"

    /// Zavolá se, když uživatel v notifikaci klikne na „Zastavit“.
    var onStopRequested: (() -> Void)?
    /// Zavolá se, když uživatel potvrdí „Pokračovat“.
    var onContinue: (() -> Void)?

    func setup() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self

        let cont = UNNotificationAction(identifier: Self.continueID, title: "Pokračovat", options: [])
        let stop = UNNotificationAction(identifier: Self.stopID, title: "Zastavit", options: [.destructive])
        let category = UNNotificationCategory(
            identifier: Self.categoryID,
            actions: [cont, stop],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([category])
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func sendReminder(projectName: String, elapsed: String) {
        let content = UNMutableNotificationContent()
        content.title = "Trackuješ ještě?"
        content.body = "„\(projectName)“ běží už \(elapsed)."
        content.categoryIdentifier = Self.categoryID
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    // Zobrazí notifikaci i když je appka v popředí.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    // Reakce na kliknutí na tlačítko v notifikaci.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let action = response.actionIdentifier
        await MainActor.run {
            if action == Self.stopID {
                self.onStopRequested?()
            } else {
                self.onContinue?()
            }
        }
    }
}
