import Foundation
import Observation

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

    private let defaults: UserDefaults

    private enum Keys {
        static let enableDNDOnFocusStart = "settings.enableDNDOnFocusStart"
        static let disableDNDOnFocusEnd = "settings.disableDNDOnFocusEnd"
        static let enableBreakNotification = "settings.enableBreakNotification"
        static let blockedWords = "settings.blockedWords"
    }

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        self.enableDNDOnFocusStart = defaults.object(forKey: Keys.enableDNDOnFocusStart) as? Bool ?? true
        self.disableDNDOnFocusEnd = defaults.object(forKey: Keys.disableDNDOnFocusEnd) as? Bool ?? true
        self.enableBreakNotification = defaults.object(forKey: Keys.enableBreakNotification) as? Bool ?? true
        let stored = (defaults.string(forKey: Keys.blockedWords) ?? "")
            .components(separatedBy: CharacterSet(charactersIn: ",，;；\n\t "))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
            .reduce(into: [String]()) { partial, word in
                if !partial.contains(word) {
                    partial.append(word)
                }
            }

        self.blockedWordsList = stored.isEmpty ? TaskKeywordAgent.defaultBlockedWords : stored

    }

    func addBlockedWord(_ word: String) {
        let normalized = word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else { return }
        guard !blockedWordsList.contains(normalized) else { return }
        blockedWordsList.append(normalized)
        blockedWordsList.sort()
    }

    func removeBlockedWord(_ word: String) {
        let normalized = word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        blockedWordsList.removeAll(where: { $0 == normalized })
    }

    func resetDefaultBlockedWords() {
        blockedWordsList = TaskKeywordAgent.defaultBlockedWords.sorted()
    }
}
