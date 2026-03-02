import Foundation

final class SessionStore {
    private let filename: String
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(filename: String = "focus-sessions.json") {
        self.filename = filename

        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func load() -> [FocusSession] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? decoder.decode([FocusSession].self, from: data)) ?? []
    }

    func save(_ sessions: [FocusSession]) {
        guard let data = try? encoder.encode(sessions) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }

    private var fileURL: URL {
        let directory = StoragePathManager.shared.currentDataDirectoryURL
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent(filename)
    }
}
