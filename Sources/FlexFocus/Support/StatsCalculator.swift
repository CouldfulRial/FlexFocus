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
            let words = tokenize(session.task)
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

    private static func tokenize(_ task: String) -> [String] {
        task
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count >= 2 }
    }

    private static func dayBuckets(sessions: [FocusSession], now: Date, calendar: Calendar) -> [TimeBucket] {
        let start = calendar.startOfDay(for: now)
        let labels = (0..<24).map { hour -> String in
            let value = calendar.date(byAdding: .hour, value: hour, to: start) ?? start
            let hourValue = calendar.component(.hour, from: value)
            return String(format: "%02d", hourValue)
        }

        var totals = Dictionary(uniqueKeysWithValues: labels.map { ($0, 0) })
        for session in sessions {
            guard calendar.isDate(session.startTime, inSameDayAs: now) else { continue }
            let hour = calendar.component(.hour, from: session.startTime)
            let key = String(format: "%02d", hour)
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
        let labels = range.map { "\($0)" }
        var totals = Dictionary(uniqueKeysWithValues: labels.map { ($0, 0) })

        for session in sessions {
            guard calendar.isDate(session.startTime, equalTo: now, toGranularity: .month) else { continue }
            let day = calendar.component(.day, from: session.startTime)
            totals["\(day)", default: 0] += session.durationSeconds
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
