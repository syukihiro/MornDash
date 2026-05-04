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
            center.stopMonitoring([Self.activityName])
            try center.startMonitoring(Self.activityName, during: schedule)
            print("Scheduled daily block at \(startHour):\(startMinute)")
        } catch {
            print("Failed to schedule: \(error.localizedDescription)")
        }
    }

    func unscheduleDailyBlock() {
        center.stopMonitoring([Self.activityName])
    }
}
