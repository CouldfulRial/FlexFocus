import Foundation

enum FocusCategory: String, CaseIterable, Codable, Identifiable {
    case research = "Research"
    case teaching = "Teaching"
    case others = "Others"

    var id: String { rawValue }
}

struct FocusSession: Identifiable, Codable, Equatable {
    var id: UUID
    var category: FocusCategory
    var startTime: Date
    var endTime: Date
    var durationSeconds: Int

    init(
        id: UUID = UUID(),
        category: FocusCategory,
        startTime: Date,
        endTime: Date,
        durationSeconds: Int? = nil
    ) {
        self.id = id
        self.category = category
        self.startTime = startTime
        self.endTime = endTime
        self.durationSeconds = durationSeconds ?? max(1, Int(endTime.timeIntervalSince(startTime)))
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case category
        case task
        case startTime
        case endTime
        case durationSeconds
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        startTime = try container.decode(Date.self, forKey: .startTime)
        endTime = try container.decode(Date.self, forKey: .endTime)
        durationSeconds = try container.decodeIfPresent(Int.self, forKey: .durationSeconds)
            ?? max(1, Int(endTime.timeIntervalSince(startTime)))

        if let decodedCategory = try container.decodeIfPresent(FocusCategory.self, forKey: .category) {
            category = decodedCategory
        } else if
            let legacyTask = try container.decodeIfPresent(String.self, forKey: .task),
            let legacyCategory = FocusCategory(rawValue: legacyTask)
        {
            category = legacyCategory
        } else {
            category = .research
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(category, forKey: .category)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(endTime, forKey: .endTime)
        try container.encode(durationSeconds, forKey: .durationSeconds)
    }
}

struct CompletedFocusSession: Equatable {
    let category: FocusCategory
    let startTime: Date
    let endTime: Date
    let durationSeconds: Int
}
