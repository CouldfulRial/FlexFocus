import Foundation
import CloudKit
import Security

final class CrossDeviceNotificationService: @unchecked Sendable {
    static let shared = CrossDeviceNotificationService()

    private let defaults = UserDefaults.standard

    private var pollTimer: Timer?
    private var hasStarted = false

    private enum Keys {
        static let deviceID = "crossDevice.deviceID"
        static let lastSeen = "crossDevice.lastSeenDate"
    }

    private init() {}

    func start() {
        guard !hasStarted else { return }
        hasStarted = true
        guard canUseCloudKit else { return }

        checkAccountStatus()

        fetchNewEvents()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 25, repeats: true) { [weak self] _ in
            self?.fetchNewEvents()
        }
    }

    func publishBreakFinishedEvent() {
        guard canUseCloudKit else { return }
        let database = CKContainer.default().privateCloudDatabase

        let record = CKRecord(recordType: "BreakFinishedEvent")
        record["deviceID"] = deviceID as CKRecordValue
        record["createdAt"] = Date() as CKRecordValue
        record["type"] = "breakFinished" as CKRecordValue

        database.save(record) { _, error in
            if let error {
                print("[CrossDevice] publish error:", error.localizedDescription)
            }
        }
    }

    private func fetchNewEvents() {
        let notificationEnabled = AppSettings.shared.enableBreakNotification
        guard notificationEnabled else { return }
        guard canUseCloudKit else { return }
        let database = CKContainer.default().privateCloudDatabase

        let sinceDate = (defaults.object(forKey: Keys.lastSeen) as? Date) ?? Date().addingTimeInterval(-3600)
        let predicate = NSPredicate(format: "createdAt > %@", sinceDate as NSDate)
        let query = CKQuery(recordType: "BreakFinishedEvent", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]

        let operation = CKQueryOperation(query: query)
        operation.resultsLimit = 50

        var maxSeenDate = sinceDate

        operation.recordMatchedBlock = { [weak self] _, result in
            guard let self else { return }
            guard case let .success(record) = result else { return }

            let createdAt = (record["createdAt"] as? Date) ?? Date()
            if createdAt > maxSeenDate {
                maxSeenDate = createdAt
            }

            let sourceDevice = (record["deviceID"] as? String) ?? ""
            if sourceDevice == self.deviceID {
                return
            }

            NotificationService.shared.sendCrossDeviceBreakFinishedNotification()
        }

        operation.queryResultBlock = { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                self.defaults.set(maxSeenDate, forKey: Keys.lastSeen)
            case .failure(let error):
                print("[CrossDevice] fetch error:", error.localizedDescription)
            }
        }

        database.add(operation)
    }

    private func checkAccountStatus() {
        let container = CKContainer.default()
        container.accountStatus { status, error in
            if let error {
                print("[CrossDevice] account status error:", error.localizedDescription)
                return
            }

            switch status {
            case .available:
                print("[CrossDevice] iCloud account available")
            case .noAccount:
                print("[CrossDevice] no iCloud account")
            case .restricted:
                print("[CrossDevice] iCloud account restricted")
            case .couldNotDetermine:
                print("[CrossDevice] iCloud account status unknown")
            case .temporarilyUnavailable:
                print("[CrossDevice] iCloud temporarily unavailable")
            @unknown default:
                print("[CrossDevice] iCloud account status unknown default")
            }
        }
    }

    private var canUseCloudKit: Bool {
        Bundle.main.bundleURL.pathExtension == "app" && hasICloudEntitlement
    }

    private var hasICloudEntitlement: Bool {
        let entitlementKey = "com.apple.developer.icloud-container-identifiers" as CFString
        let task = SecTaskCreateFromSelf(nil)
        guard let task else { return false }
        let value = SecTaskCopyValueForEntitlement(task, entitlementKey, nil)

        if let array = value as? [String] {
            return !array.isEmpty
        }
        return false
    }

    private var deviceID: String {
        if let existing = defaults.string(forKey: Keys.deviceID) {
            return existing
        }
        let newID = UUID().uuidString
        defaults.set(newID, forKey: Keys.deviceID)
        return newID
    }
}
