import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity
import Combine

class BlockManager: ObservableObject {
    @Published var selection: FamilyActivitySelection {
        didSet {
            SharedStorage.saveSelection(selection)
        }
    }

    private let store = ManagedSettingsStore()
    private let center = DeviceActivityCenter()
    static let activityName = DeviceActivityName("dailyBlock")

    private static func weekdayActivityName(_ weekday: Int) -> DeviceActivityName {
        DeviceActivityName("weekdayBlock_\(weekday)")
    }

    private static var allActivityNames: [DeviceActivityName] {
        [activityName] + (1...7).map { weekdayActivityName($0) }
    }

    init() {
        self.selection = SharedStorage.loadSelection()
    }

    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            print("Authorization successful")
        } catch {
            print("Authorization failed: \(error.localizedDescription)")
        }
    }

    /// Apply shield immediately (main app calls this when the user opens the app during an active block window).
    func applyShield() {
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty
            ? nil
            : ShieldSettings.ActivityCategoryPolicy.specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
    }

    /// Remove shield immediately (called when user completes tasks or presses give-up).
    func clearShield() {
        store.clearAllSettings()
    }

    /// Register the DeviceActivity schedule. This tells the OS to wake the extension at the
    /// user's start time every day. The extension applies the shield regardless of whether the
    /// main app is open.
    func scheduleDailyBlock(startHour: Int, startMinute: Int) {
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: startHour, minute: startMinute),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        do {
            center.stopMonitoring(Self.allActivityNames)
            try center.startMonitoring(Self.activityName, during: schedule)
            print("Scheduled daily block at \(startHour):\(startMinute)")
        } catch {
            print("Failed to schedule: \(error.localizedDescription)")
        }
    }

    /// Register seven weekday-specific schedules. Each fires only on its weekday.
    /// `times` index 0 = Sunday, 6 = Saturday (matches Calendar.weekday - 1).
    func scheduleWeekdayBlocks(_ times: [WeekdayTime]) {
        center.stopMonitoring(Self.allActivityNames)
        for weekday in 1...7 {
            let idx = weekday - 1
            guard idx < times.count else { continue }
            let t = times[idx]
            let schedule = DeviceActivitySchedule(
                intervalStart: DateComponents(hour: t.hour, minute: t.minute, weekday: weekday),
                intervalEnd: DateComponents(hour: 23, minute: 59, weekday: weekday),
                repeats: true
            )
            do {
                try center.startMonitoring(Self.weekdayActivityName(weekday), during: schedule)
            } catch {
                print("Failed to schedule weekday \(weekday): \(error.localizedDescription)")
            }
        }
    }

    func unscheduleDailyBlock() {
        center.stopMonitoring(Self.allActivityNames)
    }

    /// Free plan: categories are not persisted (they bypass the per-item cap). Pro may keep categories.
    /// Skips until RevenueCat has returned at least once so we do not clear Pro selections on a failed first fetch.
    func applyFreePlanCategoryRestrictionIfNeeded() {
        guard SubscriptionManager.shared.customerInfo != nil else { return }
        guard !SubscriptionManager.shared.isPro else { return }
        var s = selection
        guard !s.categoryTokens.isEmpty else { return }
        s.categoryTokens = []
        selection = s
    }
}
