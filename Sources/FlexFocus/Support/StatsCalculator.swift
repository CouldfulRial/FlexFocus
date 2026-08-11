import Foundation

struct TimeBucket: Identifiable {
    let label: String
    let start: Date
    let end: Date
    let totalSeconds: Int
    let previousSeconds: Int

    var id: String { label }

    var changeRatio: Double {
        if previousSeconds == 0 {
            return totalSeconds > 0 ? 1.0 : 0
        }
        return Double(totalSeconds - previousSeconds) / Double(previousSeconds)
    }
}

struct StatsWindow {
    let start: Date
    let end: Date

    var duration: TimeInterval { end.timeIntervalSince(start) }
}

struct CategoryStat: Identifiable {
    let category: FocusCategory
    let totalSeconds: Int

    var id: FocusCategory { category }
}

enum StatsCalculator {
    static func window(for range: StatisticsRange, reference: Date, calendar: Calendar = .current) -> StatsWindow {
        let referenceDayStart = calendar.startOfDay(for: reference)

        switch range {
        case .hour:
            let currentHourStart = calendar.dateInterval(of: .hour, for: reference)?.start ?? reference
            let end = calendar.date(byAdding: .hour, value: 1, to: currentHourStart) ?? currentHourStart
            let start = calendar.date(byAdding: .hour, value: -12, to: end) ?? end
            return StatsWindow(start: start, end: end)
        case .day:
            let end = calendar.date(byAdding: .day, value: 1, to: referenceDayStart) ?? referenceDayStart
            let start = calendar.date(byAdding: .day, value: -7, to: end) ?? end
            return StatsWindow(start: start, end: end)
        case .week:
            let end = calendar.date(byAdding: .day, value: 1, to: referenceDayStart) ?? referenceDayStart
            let start = calendar.date(byAdding: .day, value: -49, to: end) ?? end
            return StatsWindow(start: start, end: end)
        case .month:
            let referenceMonthStart = calendar.dateInterval(of: .month, for: referenceDayStart)?.start ?? referenceDayStart
            let start = calendar.date(byAdding: .month, value: -11, to: referenceMonthStart) ?? referenceMonthStart
            let end = calendar.date(byAdding: .day, value: 1, to: referenceDayStart) ?? referenceDayStart
            return StatsWindow(start: start, end: end)
        }
    }

    static func shiftedReference(from reference: Date, range: StatisticsRange, step: Int, calendar: Calendar = .current) -> Date {
        switch range {
        case .hour:
            return calendar.date(byAdding: .hour, value: step, to: reference) ?? reference
        case .day:
            return calendar.date(byAdding: .day, value: step, to: reference) ?? reference
        case .week:
            return calendar.date(byAdding: .weekOfYear, value: step, to: reference) ?? reference
        case .month:
            return calendar.date(byAdding: .month, value: step, to: reference) ?? reference
        }
    }

    static func buckets(for sessions: [FocusSession], range: StatisticsRange, window: StatsWindow, calendar: Calendar = .current) -> [TimeBucket] {
        let skeleton = bucketSkeleton(range: range, window: window, calendar: calendar)

        return skeleton.map { raw in
            let total = sessions.reduce(0) { partial, session in
                partial + overlapSeconds(
                    sessionStart: session.startTime,
                    sessionEnd: session.endTime,
                    bucketStart: raw.start,
                    bucketEnd: raw.end
                )
            }

            let previousInterval = previousComparisonInterval(for: range, start: raw.start, end: raw.end, calendar: calendar)
            let previousTotal = sessions.reduce(0) { partial, session in
                partial + overlapSeconds(
                    sessionStart: session.startTime,
                    sessionEnd: session.endTime,
                    bucketStart: previousInterval.start,
                    bucketEnd: previousInterval.end
                )
            }

            return TimeBucket(
                label: raw.label,
                start: raw.start,
                end: raw.end,
                totalSeconds: total,
                previousSeconds: previousTotal
            )
        }
    }

    static func sessions(in window: StatsWindow, from sessions: [FocusSession]) -> [FocusSession] {
        sessions.filter { session in
            session.endTime > window.start && session.startTime < window.end
        }
    }

    static func categoryStats(from sessions: [FocusSession], in window: StatsWindow) -> [CategoryStat] {
        FocusCategory.allCases.compactMap { category in
            let seconds = sessions
                .filter { $0.category == category }
                .reduce(0) { partial, session in
                    partial + overlapSeconds(
                        sessionStart: session.startTime,
                        sessionEnd: session.endTime,
                        bucketStart: window.start,
                        bucketEnd: window.end
                    )
                }
            guard seconds > 0 else { return nil }
            return CategoryStat(category: category, totalSeconds: seconds)
        }
    }

    private static func bucketSkeleton(range: StatisticsRange, window: StatsWindow, calendar: Calendar) -> [(label: String, start: Date, end: Date)] {
        switch range {
        case .hour:
            return (0..<12).map { index in
                let start = calendar.date(byAdding: .hour, value: index, to: window.start) ?? window.start
                let end = calendar.date(byAdding: .hour, value: 1, to: start) ?? start
                return (String(format: "%02d:00", calendar.component(.hour, from: start)), start, end)
            }
        case .day:
            return (0..<7).map { index in
                let start = calendar.date(byAdding: .day, value: index, to: window.start) ?? window.start
                let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
                return (weekdayLabel(for: start, calendar: calendar), start, end)
            }
        case .week:
            return (0..<7).map { index in
                let start = calendar.date(byAdding: .day, value: index * 7, to: window.start) ?? window.start
                let end = calendar.date(byAdding: .day, value: 7, to: start) ?? start
                return ("W\(index + 1)", start, end)
            }
        case .month:
            return (0..<12).map { index in
                let start = calendar.date(byAdding: .month, value: index, to: window.start) ?? window.start
                let end = calendar.date(byAdding: .month, value: 1, to: start) ?? start
                return ("M\(index + 1)", start, end)
            }
        }
    }

    private static func overlapSeconds(sessionStart: Date, sessionEnd: Date, bucketStart: Date, bucketEnd: Date) -> Int {
        let start = max(sessionStart, bucketStart)
        let end = min(sessionEnd, bucketEnd)
        guard end > start else { return 0 }
        return Int(end.timeIntervalSince(start))
    }

    private static func weekdayLabel(for date: Date, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    private static func previousComparisonInterval(for range: StatisticsRange, start: Date, end: Date, calendar: Calendar) -> (start: Date, end: Date) {
        switch range {
        case .hour:
            let previousStart = calendar.date(byAdding: .day, value: -1, to: start) ?? start
            let previousEnd = calendar.date(byAdding: .day, value: -1, to: end) ?? end
            return (previousStart, previousEnd)
        case .day:
            let previousStart = calendar.date(byAdding: .day, value: -7, to: start) ?? start
            let previousEnd = calendar.date(byAdding: .day, value: -7, to: end) ?? end
            return (previousStart, previousEnd)
        case .week:
            let previousStart = calendar.date(byAdding: .weekOfYear, value: -1, to: start) ?? start
            let previousEnd = calendar.date(byAdding: .weekOfYear, value: -1, to: end) ?? end
            return (previousStart, previousEnd)
        case .month:
            let previousStart = calendar.date(byAdding: .month, value: -1, to: start) ?? start
            let previousEnd = calendar.date(byAdding: .month, value: -1, to: end) ?? end
            return (previousStart, previousEnd)
        }
    }
}
