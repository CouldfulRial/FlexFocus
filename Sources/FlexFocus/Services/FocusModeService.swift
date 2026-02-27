import Foundation

struct FocusModeService {
    private let startShortcutName = "FlexFocus Start Focus"
    private let stopShortcutName = "FlexFocus Stop Focus"

    func activateFocusMode() {
        runShortcut(named: startShortcutName)
    }

    func deactivateFocusMode() {
        runShortcut(named: stopShortcutName)
    }

    private func runShortcut(named name: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
        process.arguments = ["run", name]
        try? process.run()
    }
}
