import Foundation

struct FocusSession: Identifiable, Codable, Equatable {
    var id: UUID
    var task: String
    var startTime: Date
    var endTime: Date
    var durationSeconds: Int

    init(id: UUID = UUID(), task: String, startTime: Date, endTime: Date, durationSeconds: Int) {
        self.id = id
        self.task = task
        self.startTime = startTime
        self.endTime = endTime
        self.durationSeconds = durationSeconds
    }
}

struct CompletedFocusSession: Equatable {
    let task: String
    let startTime: Date
    let endTime: Date
    let durationSeconds: Int
}
