import Foundation
import UserNotifications

struct NotificationService {
    static let shared = NotificationService()

    func requestAuthorizationIfNeeded() {
        guard canUseUserNotifications else { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func sendBreakFinishedNotification() {
        guard canUseUserNotifications else { return }
        let content = UNMutableNotificationContent()
        content.title = "休息结束"
        content.body = "可以开始下一轮专注了。"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.2, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private var canUseUserNotifications: Bool {
        Bundle.main.bundleURL.pathExtension == "app"
    }
}
