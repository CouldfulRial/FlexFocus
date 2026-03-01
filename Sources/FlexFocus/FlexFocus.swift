import SwiftUI
import AppKit

@main
struct FlexFocusApp: App {
    @State private var menuBarTimer = MenuBarTimerState.shared

    init() {
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)

        if AppSettings.shared.enableBreakNotification {
            NotificationService.shared.requestAuthorizationIfNeeded()
        }

        CrossDeviceNotificationService.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            MainContentView()
                .frame(minWidth: MainContentView.minimumWindowWidth, minHeight: MainContentView.minimumWindowHeight)
        }
        .defaultSize(width: 1520, height: 920)
        .windowResizability(.contentMinSize)

        Settings {
            SettingsView()
        }

        MenuBarExtra {
            Text(menuBarTimer.isActive ? "计时进行中" : "当前无计时")
                .padding(.bottom, 4)
            Divider()
            Button("显示主窗口") {
                NSApplication.shared.activate(ignoringOtherApps: true)
                NSApplication.shared.windows.first?.makeKeyAndOrderFront(nil)
            }
        } label: {
            Text(menuBarTimer.title)
                .monospacedDigit()
        }
    }
}
