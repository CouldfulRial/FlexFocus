import Foundation
import Combine

final class FocusViewModel: ObservableObject, @unchecked Sendable {
    @Published private(set) var phase: TimerPhase = .idle
    @Published private(set) var elapsedFocusSeconds = 0
    @Published private(set) var remainingBreakSeconds = 0
    @Published private(set) var currentCategory: FocusCategory?

    @Published var isCategoryPickerPresented = false

    private var focusStartTime: Date?
    private var timer: Timer?
    private let focusModeService = FocusModeService()
    private let settings = AppSettings.shared
    private let menuBarTimerState = MenuBarTimerState.shared

    var isFocusing: Bool {
        if case .focusing = phase { return true }
        return false
    }

    func openCategoryPicker() {
        guard !isFocusing else { return }
        isCategoryPickerPresented = true
    }

    func startFocus(category: FocusCategory) {
        stopTimer()
        currentCategory = category
        focusStartTime = Date()
        elapsedFocusSeconds = 0
        remainingBreakSeconds = 0
        phase = .focusing
        isCategoryPickerPresented = false
        focusModeService.activateFocusMode()
        menuBarTimerState.setFocus(seconds: elapsedFocusSeconds)

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.elapsedFocusSeconds += 1
            self.menuBarTimerState.setFocus(seconds: self.elapsedFocusSeconds)
        }
    }

    func endFocusManually() {
        guard
            case .focusing = phase,
            let start = focusStartTime,
            let category = currentCategory
        else { return }

        stopTimer()
        let end = Date()
        let duration = max(1, Int(end.timeIntervalSince(start)))
        focusModeService.deactivateFocusMode()

        let completed = CompletedFocusSession(
            category: category,
            startTime: start,
            endTime: end,
            durationSeconds: duration
        )
        phase = .awaitingBreakConfirmation(completed)
        menuBarTimerState.reset()
    }

    func confirmBreak() {
        guard case let .awaitingBreakConfirmation(completed) = phase else { return }

        remainingBreakSeconds = max(60, completed.durationSeconds / 5)
        phase = .breaking
        let shouldNotifyWhenDone = settings.enableBreakNotification
        menuBarTimerState.setBreak(remainingSeconds: remainingBreakSeconds)

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.remainingBreakSeconds = max(0, self.remainingBreakSeconds - 1)
            self.menuBarTimerState.setBreak(remainingSeconds: self.remainingBreakSeconds)
            if self.remainingBreakSeconds == 0 {
                if shouldNotifyWhenDone {
                    NotificationService.shared.sendBreakFinishedNotification()
                    CrossDeviceNotificationService.shared.publishBreakFinishedEvent()
                }
                self.stopTimer()
                self.resetToIdle()
            }
        }
    }

    func skipBreak() {
        stopTimer()
        resetToIdle()
    }

    func consumeCompletedFocusIfNeeded() -> CompletedFocusSession? {
        guard case let .awaitingBreakConfirmation(completed) = phase else { return nil }
        return completed
    }

    private func resetToIdle() {
        phase = .idle
        currentCategory = nil
        elapsedFocusSeconds = 0
        remainingBreakSeconds = 0
        focusStartTime = nil
        menuBarTimerState.reset()
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    deinit {
        stopTimer()
    }
}
