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

struct WordStat: Identifiable {
    let word: String
    let frequency: Int
    let totalSeconds: Double

    var id: String { word }
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

    static func wordStats(from sessions: [FocusSession], in window: StatsWindow) -> [WordStat] {
        let scopedSessions = self.sessions(in: window, from: sessions)
        var frequencyMap: [String: Int] = [:]
        var durationMap: [String: Double] = [:]

        for session in scopedSessions {
            let words = TaskKeywordAgent.shared.extractKeywords(from: session.task)
            guard !words.isEmpty else { continue }

            let effectiveSeconds = Double(overlapSeconds(
                sessionStart: session.startTime,
                sessionEnd: session.endTime,
                bucketStart: window.start,
                bucketEnd: window.end
            ))
            guard effectiveSeconds > 0 else { continue }

            let share = effectiveSeconds / Double(words.count)
            for word in words {
                frequencyMap[word, default: 0] += 1
                durationMap[word, default: 0] += share
            }
        }

        return frequencyMap
            .map { key, count in
                WordStat(word: key, frequency: count, totalSeconds: durationMap[key, default: 0])
            }
            .sorted { lhs, rhs in
                if lhs.frequency == rhs.frequency {
                    if lhs.totalSeconds == rhs.totalSeconds {
                        return lhs.word.localizedCompare(rhs.word) == .orderedAscending
                    }
                    return lhs.totalSeconds > rhs.totalSeconds
                }
                return lhs.frequency > rhs.frequency
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
                return ("第\(index + 1)周", start, end)
            }
        case .month:
            return (0..<12).map { index in
                let start = calendar.date(byAdding: .month, value: index, to: window.start) ?? window.start
                let end = calendar.date(byAdding: .month, value: 1, to: start) ?? start
                return ("\(index + 1)月", start, end)
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
        switch calendar.component(.weekday, from: date) {
        case 1: return "日"
        case 2: return "一"
        case 3: return "二"
        case 4: return "三"
        case 5: return "四"
        case 6: return "五"
        case 7: return "六"
        default: return "-"
        }
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
