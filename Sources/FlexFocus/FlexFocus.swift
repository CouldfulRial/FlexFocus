import SwiftUI
import AppKit

@main
struct FlexFocusApp: App {
    @StateObject private var menuBarTimer = MenuBarTimerState.shared
    @StateObject private var settings = AppSettings.shared

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
                .preferredColorScheme(appColorScheme)
        }
        .defaultSize(width: 1520, height: 920)
        .windowResizability(.contentMinSize)

        Settings {
            SettingsView()
        }

        MenuBarExtra {
            Text(menuBarTimer.isActive ? "Timer active" : "No active timer")
                .padding(.bottom, 4)
            Divider()
            Button("Show Main Window") {
                NSApplication.shared.activate(ignoringOtherApps: true)
                NSApplication.shared.windows.first?.makeKeyAndOrderFront(nil)
            }
        } label: {
            Text(menuBarTimer.title)
                .monospacedDigit()
        }
    }

    private var appColorScheme: ColorScheme? {
        switch settings.themeMode {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}
