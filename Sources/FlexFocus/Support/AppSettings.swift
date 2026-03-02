import Foundation
import Observation

enum VocabularyFilterMode: String, CaseIterable, Identifiable {
    case blacklist
    case whitelist

    var id: String { rawValue }

    var title: String {
        switch self {
        case .blacklist:
            return "黑名单"
        case .whitelist:
            return "白名单"
        }
    }
}

enum AppThemeMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system:
            return "跟随系统"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }
}

@Observable
final class AppSettings: @unchecked Sendable {
    static let shared = AppSettings()

    var enableDNDOnFocusStart: Bool {
        didSet { persistProfile() }
    }

    var disableDNDOnFocusEnd: Bool {
        didSet { persistProfile() }
    }

    var enableBreakNotification: Bool {
        didSet {
            persistProfile()
            if enableBreakNotification {
                NotificationService.shared.requestAuthorizationIfNeeded()
            }
        }
    }

    var blockedWordsList: [String] {
        didSet { persistProfile() }
    }

    var whitelistWordsList: [String] {
        didSet { persistProfile() }
    }

    var vocabularyModeRawValue: String {
        didSet { persistProfile() }
    }

    var themeModeRawValue: String {
        didSet { persistProfile() }
    }

    var invertThemeColorsInDarkMode: Bool {
        didSet { persistProfile() }
    }

    var vocabularyMode: VocabularyFilterMode {
        get { VocabularyFilterMode(rawValue: vocabularyModeRawValue) ?? .blacklist }
        set { vocabularyModeRawValue = newValue.rawValue }
    }

    var currentModeWordsList: [String] {
        switch vocabularyMode {
        case .blacklist:
            return blockedWordsList
        case .whitelist:
            return whitelistWordsList
        }
    }

    var themeMode: AppThemeMode {
        get { AppThemeMode(rawValue: themeModeRawValue) ?? .system }
        set { themeModeRawValue = newValue.rawValue }
    }

    private let profileFileName = "settings-profile.json"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private struct SettingsProfile: Codable {
        var enableDNDOnFocusStart: Bool
        var disableDNDOnFocusEnd: Bool
        var enableBreakNotification: Bool
        var blockedWordsList: [String]
        var whitelistWordsList: [String]
        var vocabularyModeRawValue: String
        var themeModeRawValue: String
        var invertThemeColorsInDarkMode: Bool
    }

    private enum Keys {
        static let enableDNDOnFocusStart = "settings.enableDNDOnFocusStart"
        static let disableDNDOnFocusEnd = "settings.disableDNDOnFocusEnd"
        static let enableBreakNotification = "settings.enableBreakNotification"
        static let blockedWords = "settings.blockedWords"
        static let whitelistWords = "settings.whitelistWords"
        static let vocabularyMode = "settings.vocabularyMode"
        static let themeMode = "settings.themeMode"
        static let invertThemeColorsInDarkMode = "settings.invertThemeColorsInDarkMode"
    }

    private init() {
        let url = Self.currentProfileURL(fileName: profileFileName)
        let initialProfile = Self.loadProfileFromFile(at: url) ?? Self.migrateFromUserDefaults(UserDefaults.standard)

        self.enableDNDOnFocusStart = initialProfile.enableDNDOnFocusStart
        self.disableDNDOnFocusEnd = initialProfile.disableDNDOnFocusEnd
        self.enableBreakNotification = initialProfile.enableBreakNotification
        self.blockedWordsList = initialProfile.blockedWordsList
        self.whitelistWordsList = initialProfile.whitelistWordsList
        self.vocabularyModeRawValue = initialProfile.vocabularyModeRawValue
        self.themeModeRawValue = initialProfile.themeModeRawValue
        self.invertThemeColorsInDarkMode = initialProfile.invertThemeColorsInDarkMode

        if Self.loadProfileFromFile(at: url) == nil {
            persistProfile()
        }
    }

    func addCurrentModeWord(_ word: String) {
        let normalized = word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else { return }

        switch vocabularyMode {
        case .blacklist:
            guard !blockedWordsList.contains(normalized) else { return }
            blockedWordsList.append(normalized)
            blockedWordsList.sort()
        case .whitelist:
            guard !whitelistWordsList.contains(normalized) else { return }
            whitelistWordsList.append(normalized)
            whitelistWordsList.sort()
        }
    }

    func removeCurrentModeWord(_ word: String) {
        let normalized = word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        switch vocabularyMode {
        case .blacklist:
            blockedWordsList.removeAll(where: { $0 == normalized })
        case .whitelist:
            whitelistWordsList.removeAll(where: { $0 == normalized })
        }
    }

    func resetCurrentModeWords() {
        switch vocabularyMode {
        case .blacklist:
            blockedWordsList = TaskKeywordAgent.defaultBlockedWords.sorted()
        case .whitelist:
            whitelistWordsList = []
        }
    }

    private static func parseWordList(_ raw: String) -> [String] {
        raw
            .components(separatedBy: CharacterSet(charactersIn: ",，;；\n\t"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
            .reduce(into: [String]()) { partial, word in
                if !partial.contains(word) {
                    partial.append(word)
                }
            }
    }

    private static func loadProfileFromFile(at url: URL) -> SettingsProfile? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(SettingsProfile.self, from: data)
    }

    private func persistProfile() {
        let profile = SettingsProfile(
            enableDNDOnFocusStart: enableDNDOnFocusStart,
            disableDNDOnFocusEnd: disableDNDOnFocusEnd,
            enableBreakNotification: enableBreakNotification,
            blockedWordsList: blockedWordsList,
            whitelistWordsList: whitelistWordsList,
            vocabularyModeRawValue: vocabularyModeRawValue,
            themeModeRawValue: themeModeRawValue,
            invertThemeColorsInDarkMode: invertThemeColorsInDarkMode
        )

        guard let data = try? encoder.encode(profile) else { return }
        try? data.write(to: profileURL, options: .atomic)
    }

    private static func migrateFromUserDefaults(_ defaults: UserDefaults) -> SettingsProfile {
        let blockedStored = Self.parseWordList(defaults.string(forKey: Keys.blockedWords) ?? "")
        let blockedWordsList = blockedStored.isEmpty ? TaskKeywordAgent.defaultBlockedWords : blockedStored

        return SettingsProfile(
            enableDNDOnFocusStart: defaults.object(forKey: Keys.enableDNDOnFocusStart) as? Bool ?? true,
            disableDNDOnFocusEnd: defaults.object(forKey: Keys.disableDNDOnFocusEnd) as? Bool ?? true,
            enableBreakNotification: defaults.object(forKey: Keys.enableBreakNotification) as? Bool ?? true,
            blockedWordsList: blockedWordsList,
            whitelistWordsList: Self.parseWordList(defaults.string(forKey: Keys.whitelistWords) ?? ""),
            vocabularyModeRawValue: defaults.string(forKey: Keys.vocabularyMode) ?? VocabularyFilterMode.blacklist.rawValue,
            themeModeRawValue: defaults.string(forKey: Keys.themeMode) ?? AppThemeMode.system.rawValue,
            invertThemeColorsInDarkMode: defaults.object(forKey: Keys.invertThemeColorsInDarkMode) as? Bool ?? true
        )
    }

    private var profileURL: URL {
        Self.currentProfileURL(fileName: profileFileName)
    }

    private static func currentProfileURL(fileName: String) -> URL {
        let directory = StoragePathManager.shared.currentDataDirectoryURL
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent(fileName)
    }
}
