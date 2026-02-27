import SwiftUI
import AppKit

@main
struct FlexFocusApp: App {
    init() {
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)

        if AppSettings.shared.enableBreakNotification {
            NotificationService.shared.requestAuthorizationIfNeeded()
        }
    }

    var body: some Scene {
        WindowGroup {
            MainContentView()
        }
        .defaultSize(width: 1520, height: 920)

        Settings {
            SettingsView()
        }
    }
}
