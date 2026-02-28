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

@Observable
final class AppSettings: @unchecked Sendable {
    static let shared = AppSettings()

    var enableDNDOnFocusStart: Bool {
        didSet { defaults.set(enableDNDOnFocusStart, forKey: Keys.enableDNDOnFocusStart) }
    }

    var disableDNDOnFocusEnd: Bool {
        didSet { defaults.set(disableDNDOnFocusEnd, forKey: Keys.disableDNDOnFocusEnd) }
    }

    var enableBreakNotification: Bool {
        didSet {
            defaults.set(enableBreakNotification, forKey: Keys.enableBreakNotification)
            if enableBreakNotification {
                NotificationService.shared.requestAuthorizationIfNeeded()
            }
        }
    }

    var blockedWordsList: [String] {
        didSet {
            defaults.set(blockedWordsList.joined(separator: ","), forKey: Keys.blockedWords)
        }
    }

    var whitelistWordsList: [String] {
        didSet {
            defaults.set(whitelistWordsList.joined(separator: ","), forKey: Keys.whitelistWords)
        }
    }

    var vocabularyModeRawValue: String {
        didSet {
            defaults.set(vocabularyModeRawValue, forKey: Keys.vocabularyMode)
        }
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

    private let defaults: UserDefaults

    private enum Keys {
        static let enableDNDOnFocusStart = "settings.enableDNDOnFocusStart"
        static let disableDNDOnFocusEnd = "settings.disableDNDOnFocusEnd"
        static let enableBreakNotification = "settings.enableBreakNotification"
        static let blockedWords = "settings.blockedWords"
        static let whitelistWords = "settings.whitelistWords"
        static let vocabularyMode = "settings.vocabularyMode"
    }

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        self.enableDNDOnFocusStart = defaults.object(forKey: Keys.enableDNDOnFocusStart) as? Bool ?? true
        self.disableDNDOnFocusEnd = defaults.object(forKey: Keys.disableDNDOnFocusEnd) as? Bool ?? true
        self.enableBreakNotification = defaults.object(forKey: Keys.enableBreakNotification) as? Bool ?? true
        self.vocabularyModeRawValue = defaults.string(forKey: Keys.vocabularyMode) ?? VocabularyFilterMode.blacklist.rawValue

        let blockedStored = Self.parseWordList(defaults.string(forKey: Keys.blockedWords) ?? "")
        self.blockedWordsList = blockedStored.isEmpty ? TaskKeywordAgent.defaultBlockedWords : blockedStored

        self.whitelistWordsList = Self.parseWordList(defaults.string(forKey: Keys.whitelistWords) ?? "")

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
}
