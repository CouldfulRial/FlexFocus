import Foundation
import Combine

enum AppThemeMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system:
            return "System"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }
}

final class AppSettings: ObservableObject, @unchecked Sendable {
    static let shared = AppSettings()

    @Published var enableDNDOnFocusStart: Bool {
        didSet { persistProfile() }
    }

    @Published var disableDNDOnFocusEnd: Bool {
        didSet { persistProfile() }
    }

    @Published var enableBreakNotification: Bool {
        didSet {
            persistProfile()
            if enableBreakNotification {
                NotificationService.shared.requestAuthorizationIfNeeded()
            }
        }
    }

    @Published var themeModeRawValue: String {
        didSet { persistProfile() }
    }

    @Published var invertThemeColorsInDarkMode: Bool {
        didSet { persistProfile() }
    }

    var themeMode: AppThemeMode {
        get { AppThemeMode(rawValue: themeModeRawValue) ?? .system }
        set { themeModeRawValue = newValue.rawValue }
    }

    private let profileFileName = "settings-profile.json"
    private let encoder = JSONEncoder()

    private struct SettingsProfile: Codable {
        var enableDNDOnFocusStart: Bool
        var disableDNDOnFocusEnd: Bool
        var enableBreakNotification: Bool
        var themeModeRawValue: String
        var invertThemeColorsInDarkMode: Bool
    }

    private enum Keys {
        static let enableDNDOnFocusStart = "settings.enableDNDOnFocusStart"
        static let disableDNDOnFocusEnd = "settings.disableDNDOnFocusEnd"
        static let enableBreakNotification = "settings.enableBreakNotification"
        static let themeMode = "settings.themeMode"
        static let invertThemeColorsInDarkMode = "settings.invertThemeColorsInDarkMode"
    }

    private init() {
        let url = Self.currentProfileURL(fileName: profileFileName)
        let initialProfile = Self.loadProfileFromFile(at: url)
            ?? Self.migrateFromUserDefaults(UserDefaults.standard)

        enableDNDOnFocusStart = initialProfile.enableDNDOnFocusStart
        disableDNDOnFocusEnd = initialProfile.disableDNDOnFocusEnd
        enableBreakNotification = initialProfile.enableBreakNotification
        themeModeRawValue = initialProfile.themeModeRawValue
        invertThemeColorsInDarkMode = initialProfile.invertThemeColorsInDarkMode

        persistProfile()
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
            themeModeRawValue: themeModeRawValue,
            invertThemeColorsInDarkMode: invertThemeColorsInDarkMode
        )

        guard let data = try? encoder.encode(profile) else { return }
        try? data.write(to: profileURL, options: .atomic)
    }

    private static func migrateFromUserDefaults(_ defaults: UserDefaults) -> SettingsProfile {
        SettingsProfile(
            enableDNDOnFocusStart: defaults.object(forKey: Keys.enableDNDOnFocusStart) as? Bool ?? true,
            disableDNDOnFocusEnd: defaults.object(forKey: Keys.disableDNDOnFocusEnd) as? Bool ?? true,
            enableBreakNotification: defaults.object(forKey: Keys.enableBreakNotification) as? Bool ?? true,
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
