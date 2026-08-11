import SwiftUI

struct FocusHistoryView: View {
    let sessions: [FocusSession]
    let onUpdateSession: (UUID, FocusCategory, Date, Date) -> Void

    @State private var editingSession: FocusSession?
    @State private var editedCategory: FocusCategory = .research
    @State private var editedStartTime = Date()
    @State private var editedEndTime = Date()

    private let calendar = Calendar.current

    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    var body: some View {
        List {
            ForEach(visibleSessions.groupedByDayDescending()) { group in
                Section(dayFormatter.string(from: group.date)) {
                    ForEach(group.sessions) { session in
                        HStack(alignment: .center, spacing: 10) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(session.category.rawValue)
                                    .font(.headline)
                                Text("\(timeFormatter.string(from: session.startTime))–\(timeFormatter.string(from: session.endTime))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button {
                                beginEditing(session)
                            } label: {
                                Image(systemName: "pencil")
                                    .accessibilityLabel("Edit session")
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 4)
                        .contextMenu {
                            Button("Edit Session") {
                                beginEditing(session)
                            }
                        }
                    }
                }
            }
        }
        .overlay {
            if visibleSessions.isEmpty {
                ContentUnavailableView(
                    "No Focus History",
                    systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90",
                    description: Text("Sessions from the last seven days will appear here.")
                )
            }
        }
        .sheet(item: $editingSession) { session in
            VStack(alignment: .leading, spacing: 14) {
                Text("Edit Session")
                    .font(.headline)

                Picker("Category", selection: $editedCategory) {
                    ForEach(FocusCategory.allCases) { category in
                        Text(category.rawValue).tag(category)
                    }
                }

                DatePicker(
                    "Start",
                    selection: $editedStartTime,
                    in: ...Date(),
                    displayedComponents: [.date, .hourAndMinute]
                )

                DatePicker(
                    "Stop",
                    selection: $editedEndTime,
                    in: ...Date(),
                    displayedComponents: [.date, .hourAndMinute]
                )

                if !hasValidEditedTimes {
                    Text("Stop time must be later than start time.")
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                HStack {
                    Spacer()
                    Button("Cancel") {
                        editingSession = nil
                    }
                    Button("Save") {
                        guard hasValidEditedTimes else { return }
                        onUpdateSession(session.id, editedCategory, editedStartTime, editedEndTime)
                        editingSession = nil
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!hasValidEditedTimes)
                }
            }
            .padding()
            .frame(width: 390)
        }
    }

    private var visibleSessions: [FocusSession] {
        let today = calendar.startOfDay(for: Date())
        let cutoff = calendar.date(byAdding: .day, value: -6, to: today) ?? today
        return sessions.filter { $0.startTime >= cutoff }
    }

    private var hasValidEditedTimes: Bool {
        editedEndTime > editedStartTime
    }

    private func beginEditing(_ session: FocusSession) {
        editedCategory = session.category
        editedStartTime = session.startTime
        editedEndTime = session.endTime
        editingSession = session
    }
}
