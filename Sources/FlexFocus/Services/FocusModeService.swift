import Foundation

struct FocusModeService {
    private let startShortcutName = "FlexFocus Start Focus"
    private let stopShortcutName = "FlexFocus Stop Focus"
    private let settings = AppSettings.shared

    func activateFocusMode() {
        guard settings.enableDNDOnFocusStart else { return }
        runShortcut(named: startShortcutName)
    }

    func deactivateFocusMode() {
        guard settings.disableDNDOnFocusEnd else { return }
        runShortcut(named: stopShortcutName)
    }

    private func runShortcut(named name: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
        process.arguments = ["run", name]
        try? process.run()
    }
}
