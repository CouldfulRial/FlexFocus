import SwiftUI

struct FocusHistoryView: View {
    let sessions: [FocusSession]
    let onUpdateTask: (UUID, String) -> Void
    let onDeleteSession: (UUID) -> Void

    @State private var editingSession: FocusSession?
    @State private var editedTask: String = ""

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
                        .contextMenu {
                            Button("编辑任务") {
                                editingSession = session
                                editedTask = session.task
                            }
                            Button("删除记录", role: .destructive) {
                                onDeleteSession(session.id)
                            }
                        }
                    }
                }
            }
        }
        .overlay {
            if sessions.isEmpty {
                ContentUnavailableView("暂无专注历史", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
            }
        }
        .sheet(item: $editingSession) { session in
            VStack(alignment: .leading, spacing: 12) {
                Text("编辑任务")
                    .font(.headline)

                TextField("任务名称", text: $editedTask)
                    .textFieldStyle(.roundedBorder)

                HStack {
                    Spacer()
                    Button("取消") {
                        editingSession = nil
                    }
                    Button("保存") {
                        let trimmed = editedTask.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        onUpdateTask(session.id, trimmed)
                        editingSession = nil
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(editedTask.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding()
            .frame(width: 360)
        }
    }

    private func durationText(_ seconds: Int) -> String {
        let hour = seconds / 3600
        let minute = (seconds % 3600) / 60
        let sec = seconds % 60
        return String(format: "%02d:%02d:%02d", hour, minute, sec)
    }
}
