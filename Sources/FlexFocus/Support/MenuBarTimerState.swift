import Foundation
import Observation

@Observable
final class MenuBarTimerState: @unchecked Sendable {
    static let shared = MenuBarTimerState()

    private(set) var isActive = false
    private(set) var title = "FlexFocus"

    private init() {}

    func setFocus(seconds: Int) {
        isActive = true
        title = "专注 \(format(seconds))"
    }

    func setBreak(remainingSeconds: Int) {
        isActive = true
        title = "休息 \(format(remainingSeconds))"
    }

    func reset() {
        isActive = false
        title = "FlexFocus"
    }

    private func format(_ seconds: Int) -> String {
        let hour = seconds / 3600
        let minute = (seconds % 3600) / 60
        let second = seconds % 60
        return String(format: "%02d:%02d:%02d", hour, minute, second)
    }
}
