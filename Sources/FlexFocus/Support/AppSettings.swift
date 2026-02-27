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

    private let defaults: UserDefaults

    private enum Keys {
        static let enableDNDOnFocusStart = "settings.enableDNDOnFocusStart"
        static let disableDNDOnFocusEnd = "settings.disableDNDOnFocusEnd"
        static let enableBreakNotification = "settings.enableBreakNotification"
    }

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        self.enableDNDOnFocusStart = defaults.object(forKey: Keys.enableDNDOnFocusStart) as? Bool ?? true
        self.disableDNDOnFocusEnd = defaults.object(forKey: Keys.disableDNDOnFocusEnd) as? Bool ?? true
        self.enableBreakNotification = defaults.object(forKey: Keys.enableBreakNotification) as? Bool ?? true

    }
}
