import Foundation
import UserNotifications

struct NotificationService {
    static let shared = NotificationService()

    func requestAuthorizationIfNeeded() {
        guard canUseUserNotifications else { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func sendBreakFinishedNotification() {
        sendLocalNotification(title: "Break Finished", body: "You can start the next focus session.")
    }

    func sendCrossDeviceBreakFinishedNotification() {
        sendLocalNotification(title: "Break Finished on Another Device", body: "Your break on another device has ended.")
    }

    private func sendLocalNotification(title: String, body: String) {
        guard canUseUserNotifications else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.2, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private var canUseUserNotifications: Bool {
        Bundle.main.bundleURL.pathExtension == "app"
    }
}
