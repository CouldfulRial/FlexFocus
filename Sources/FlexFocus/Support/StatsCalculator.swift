import Foundation

struct TimeBucket: Identifiable {
    let label: String
    let totalSeconds: Int

    var id: String { label }
}

struct WordStat: Identifiable {
    let word: String
    let frequency: Int
    let totalSeconds: Double

    var id: String { word }
}

enum StatsCalculator {
    static func buckets(for sessions: [FocusSession], range: StatisticsRange, now: Date = .now, calendar: Calendar = .current) -> [TimeBucket] {
        switch range {
        case .day:
            return dayBuckets(sessions: sessions, now: now, calendar: calendar)
        case .week:
            return weekBuckets(sessions: sessions, now: now, calendar: calendar)
        case .month:
            return monthBuckets(sessions: sessions, now: now, calendar: calendar)
        case .year:
            return yearBuckets(sessions: sessions, now: now, calendar: calendar)
        }
    }

    static func wordStats(from sessions: [FocusSession]) -> [WordStat] {
        var frequencyMap: [String: Int] = [:]
        var durationMap: [String: Double] = [:]

        for session in sessions {
            let words = TaskKeywordAgent.shared.extractKeywords(from: session.task)
            guard !words.isEmpty else { continue }

            let share = Double(session.durationSeconds) / Double(words.count)
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
                    return lhs.totalSeconds > rhs.totalSeconds
                }
                return lhs.frequency > rhs.frequency
            }
    }

    private static func dayBuckets(sessions: [FocusSession], now: Date, calendar: Calendar) -> [TimeBucket] {
        let start = calendar.startOfDay(for: now)
        let labels = stride(from: 0, to: 24, by: 2).map { hour -> String in
            let value = calendar.date(byAdding: .hour, value: hour, to: start) ?? start
            let hourValue = calendar.component(.hour, from: value)
            let next = (hourValue + 2) % 24
            return String(format: "%02d-%02d", hourValue, next)
        }

        var totals = Dictionary(uniqueKeysWithValues: labels.map { ($0, 0) })
        for session in sessions {
            guard calendar.isDate(session.startTime, inSameDayAs: now) else { continue }
            let hour = calendar.component(.hour, from: session.startTime)
            let bucketStart = (hour / 2) * 2
            let key = String(format: "%02d-%02d", bucketStart, (bucketStart + 2) % 24)
            totals[key, default: 0] += session.durationSeconds
        }

        return labels.map { TimeBucket(label: $0, totalSeconds: totals[$0, default: 0]) }
    }

    private static func weekBuckets(sessions: [FocusSession], now: Date, calendar: Calendar) -> [TimeBucket] {
        let weekdaySymbols = ["一", "二", "三", "四", "五", "六", "日"]
        var totals = Dictionary(uniqueKeysWithValues: weekdaySymbols.map { ($0, 0) })

        for session in sessions {
            guard calendar.isDate(session.startTime, equalTo: now, toGranularity: .weekOfYear) else { continue }
            let weekday = calendar.component(.weekday, from: session.startTime)
            let idx = (weekday + 5) % 7
            totals[weekdaySymbols[idx], default: 0] += session.durationSeconds
        }

        return weekdaySymbols.map { TimeBucket(label: $0, totalSeconds: totals[$0, default: 0]) }
    }

    private static func monthBuckets(sessions: [FocusSession], now: Date, calendar: Calendar) -> [TimeBucket] {
        let range = calendar.range(of: .day, in: .month, for: now) ?? 1..<32
        let days = Array(range)
        let groups = stride(from: 0, to: days.count, by: 3).map { index -> ClosedRange<Int> in
            let first = days[index]
            let last = days[min(index + 2, days.count - 1)]
            return first...last
        }
        let labels = groups.map { group in
            if group.lowerBound == group.upperBound {
                return "\(group.lowerBound)"
            }
            return "\(group.lowerBound)-\(group.upperBound)"
        }
        var totals = Dictionary(uniqueKeysWithValues: labels.map { ($0, 0) })

        for session in sessions {
            guard calendar.isDate(session.startTime, equalTo: now, toGranularity: .month) else { continue }
            let day = calendar.component(.day, from: session.startTime)
            let groupIndex = max(0, (day - 1) / 3)
            let group = groups[min(groupIndex, groups.count - 1)]
            let label = group.lowerBound == group.upperBound ? "\(group.lowerBound)" : "\(group.lowerBound)-\(group.upperBound)"
            totals[label, default: 0] += session.durationSeconds
        }

        return labels.map { TimeBucket(label: $0, totalSeconds: totals[$0, default: 0]) }
    }

    private static func yearBuckets(sessions: [FocusSession], now: Date, calendar: Calendar) -> [TimeBucket] {
        let labels = (1...12).map { "\($0)月" }
        var totals = Dictionary(uniqueKeysWithValues: labels.map { ($0, 0) })

        for session in sessions {
            guard calendar.isDate(session.startTime, equalTo: now, toGranularity: .year) else { continue }
            let month = calendar.component(.month, from: session.startTime)
            totals["\(month)月", default: 0] += session.durationSeconds
        }

        return labels.map { TimeBucket(label: $0, totalSeconds: totals[$0, default: 0]) }
    }
}
