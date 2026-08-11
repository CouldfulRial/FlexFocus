import Foundation
import Combine

final class MenuBarTimerState: ObservableObject, @unchecked Sendable {
    static let shared = MenuBarTimerState()

    @Published private(set) var isActive = false
    @Published private(set) var title = "FlexFocus"

    private init() {}

    func setFocus(seconds: Int) {
        isActive = true
        title = "Focus \(format(seconds))"
    }

    func setBreak(remainingSeconds: Int) {
        isActive = true
        title = "Break \(format(remainingSeconds))"
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
