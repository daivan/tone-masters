import UserNotifications
import SwiftUI
import Combine

final class RestReminderManager: ObservableObject {
    static let shared = RestReminderManager()

    @AppStorage("reminder_enabled") var isEnabled: Bool = true
    @AppStorage("reminder_minutes") var reminderMinutes: Int = 20

    private let notificationID = "com.tonemasters.restreminder"

    // MARK: - Permission

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    // MARK: - Schedule / cancel

    /// Call when an exercise session starts. Schedules a notification for reminderMinutes from now.
    func scheduleReminder() {
        guard isEnabled else { return }

        cancelReminder()    // clear any stale one first

        let content = UNMutableNotificationContent()
        content.title = "Time to rest your voice"
        content.body  = "You've been singing for \(reminderMinutes) minutes. Great work — take a short break!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(reminderMinutes * 60),
            repeats: false
        )

        let request = UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    /// Call when the user exits an exercise. Cancels the pending reminder.
    func cancelReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationID])
    }
}
