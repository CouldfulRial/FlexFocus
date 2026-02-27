import SwiftUI

struct FocusHistoryView: View {
    let sessions: [FocusSession]

    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    var body: some View {
        List {
            ForEach(sessions.groupedByDayDescending()) { group in
                Section(dayFormatter.string(from: group.date)) {
                    ForEach(group.sessions) { session in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(session.task)
                                .font(.headline)
                            Text("时长：\(durationText(session.durationSeconds))")
                                .font(.subheadline)
                            Text("\(timeFormatter.string(from: session.startTime)) - \(timeFormatter.string(from: session.endTime))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .overlay {
            if sessions.isEmpty {
                ContentUnavailableView("暂无专注历史", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
            }
        }
    }

    private func durationText(_ seconds: Int) -> String {
        let hour = seconds / 3600
        let minute = (seconds % 3600) / 60
        let sec = seconds % 60
        return String(format: "%02d:%02d:%02d", hour, minute, sec)
    }
}
