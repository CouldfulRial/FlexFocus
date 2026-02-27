import Foundation
import Observation

@Observable
final class FocusViewModel {
    private(set) var phase: TimerPhase = .idle
    private(set) var elapsedFocusSeconds = 0
    private(set) var remainingBreakSeconds = 0
    private(set) var currentTask = ""

    var isTaskSheetPresented = false

    private var focusStartTime: Date?
    private var timer: Timer?
    private let focusModeService = FocusModeService()

    var isFocusing: Bool {
        if case .focusing = phase { return true }
        return false
    }

    func openTaskInput() {
        guard !isFocusing else { return }
        isTaskSheetPresented = true
    }

    func startFocus(task: String) {
        let trimmed = task.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        stopTimer()
        currentTask = trimmed
        focusStartTime = Date()
        elapsedFocusSeconds = 0
        remainingBreakSeconds = 0
        phase = .focusing
        isTaskSheetPresented = false
        focusModeService.activateFocusMode()

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.elapsedFocusSeconds += 1
        }
    }

    func endFocusManually() {
        guard case .focusing = phase, let start = focusStartTime else { return }

        stopTimer()
        let end = Date()
        let duration = max(1, Int(end.timeIntervalSince(start)))
        focusModeService.deactivateFocusMode()

        let completed = CompletedFocusSession(
            task: currentTask,
            startTime: start,
            endTime: end,
            durationSeconds: duration
        )
        phase = .awaitingBreakConfirmation(completed)
    }

    func confirmBreak() {
        guard case let .awaitingBreakConfirmation(completed) = phase else { return }

        remainingBreakSeconds = max(60, completed.durationSeconds / 5)
        phase = .breaking

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.remainingBreakSeconds = max(0, self.remainingBreakSeconds - 1)
            if self.remainingBreakSeconds == 0 {
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
        currentTask = ""
        elapsedFocusSeconds = 0
        remainingBreakSeconds = 0
        focusStartTime = nil
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    deinit {
        stopTimer()
    }
}
