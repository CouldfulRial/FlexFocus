import Foundation

enum TimerPhase: Equatable {
    case idle
    case focusing
    case awaitingBreakConfirmation(CompletedFocusSession)
    case breaking
}

enum StatisticsRange: String, CaseIterable, Identifiable {
    case hour = "Hour"
    case day = "Day"
    case week = "Week"
    case month = "Month"

    var id: String { rawValue }
}
