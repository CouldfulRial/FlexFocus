import Foundation

final class StoragePathManager: @unchecked Sendable {
    static let shared = StoragePathManager()

    private let fileManager = FileManager.default
    private let locationFileName = "storage-location.json"
    private let managedFileNames = ["focus-sessions.json", "settings-profile.json"]

    struct LocationProfile: Codable {
        let customPath: String?
    }

    private init() {}

    var defaultDirectoryURL: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = appSupport.appendingPathComponent("FlexFocus", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    var currentDataDirectoryURL: URL {
        guard
            let data = try? Data(contentsOf: locationProfileURL),
            let profile = try? JSONDecoder().decode(LocationProfile.self, from: data),
            let customPath = profile.customPath,
            !customPath.isEmpty
        else {
            return defaultDirectoryURL
        }

        let url = URL(fileURLWithPath: customPath, isDirectory: true)
        try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    func updateDataDirectory(to newDirectoryURL: URL) {
        let destination = newDirectoryURL.standardizedFileURL
        let current = currentDataDirectoryURL.standardizedFileURL

        guard destination != current else { return }

        try? fileManager.createDirectory(at: destination, withIntermediateDirectories: true)

        for fileName in managedFileNames {
            let source = current.appendingPathComponent(fileName)
            let target = destination.appendingPathComponent(fileName)
            migrateFile(from: source, to: target)
        }

        let profile = LocationProfile(customPath: destination.path)
        if let data = try? JSONEncoder().encode(profile) {
            try? data.write(to: locationProfileURL, options: .atomic)
        }

        NotificationCenter.default.post(name: .storageDirectoryDidChange, object: nil)
    }

    private var locationProfileURL: URL {
        defaultDirectoryURL.appendingPathComponent(locationFileName)
    }

    private func migrateFile(from source: URL, to target: URL) {
        guard fileManager.fileExists(atPath: source.path) else { return }

        if fileManager.fileExists(atPath: target.path) {
            if let data = try? Data(contentsOf: source) {
                try? data.write(to: target, options: .atomic)
            }
            try? fileManager.removeItem(at: source)
            return
        }

        do {
            try fileManager.moveItem(at: source, to: target)
        } catch {
            if let data = try? Data(contentsOf: source) {
                try? data.write(to: target, options: .atomic)
            }
            try? fileManager.removeItem(at: source)
        }
    }
}