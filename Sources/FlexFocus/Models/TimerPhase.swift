import Foundation

enum TimerPhase: Equatable {
    case idle
    case focusing
    case awaitingBreakConfirmation(CompletedFocusSession)
    case breaking
}

enum StatisticsRange: String, CaseIterable, Identifiable {
    case day = "天"
    case week = "周"
    case month = "月"
    case year = "年"

    var id: String { rawValue }
}
