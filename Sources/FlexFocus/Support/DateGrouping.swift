import Foundation

struct DayGroup: Identifiable {
    let date: Date
    let sessions: [FocusSession]

    var id: Date { date }
}

extension Array where Element == FocusSession {
    func groupedByDayDescending(calendar: Calendar = .current) -> [DayGroup] {
        let grouped = Dictionary(grouping: self) { session in
            calendar.startOfDay(for: session.startTime)
        }

        return grouped
            .map { DayGroup(date: $0.key, sessions: $0.value.sorted(by: { $0.startTime > $1.startTime })) }
            .sorted(by: { $0.date > $1.date })
    }
}
