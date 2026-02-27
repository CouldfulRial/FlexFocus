import Foundation
import UserNotifications

struct NotificationService {
    static let shared = NotificationService()

    func requestAuthorizationIfNeeded() {
        guard canUseUserNotifications else { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func sendBreakFinishedNotification() {
        sendLocalNotification(title: "休息结束", body: "可以开始下一轮专注了。")
    }

    func sendCrossDeviceBreakFinishedNotification() {
        sendLocalNotification(title: "其他设备休息结束", body: "你在另一台设备上的休息已结束。")
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
