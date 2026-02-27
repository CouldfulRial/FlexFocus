import SwiftUI
import AppKit

@main
struct FlexFocusApp: App {
    init() {
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    var body: some Scene {
        WindowGroup {
            MainContentView()
        }
    }
}
