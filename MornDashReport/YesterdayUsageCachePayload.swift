import Foundation
import FamilyControls

/// Duplicated under `MornDash/Models/` for the main app — keep keys and fields identical.
enum YesterdayUsageCachePayload {
    static let storageKey = "onboardingYesterdayUsageCacheV1"
    static let appGroupId = "group.danchi.MornDash"

    struct Row: Codable {
        let name: String
        let durationSeconds: Int
        let singleAppSelectionData: Data
    }

    struct Snapshot: Codable {
        let savedAt: Date
        let rows: [Row]
    }

    static func save(from apps: [AppUsage]) {
        let rows: [Row] = apps.prefix(50).compactMap { app in
            guard let token = app.token else { return nil }
            var sel = FamilyActivitySelection()
            sel.applicationTokens = [token]
            guard let data = try? PropertyListEncoder().encode(sel) else { return nil }
            return Row(
                name: app.name,
                durationSeconds: max(0, Int(app.duration)),
                singleAppSelectionData: data
            )
        }
        let snapshot = Snapshot(savedAt: Date(), rows: rows)
        guard let data = try? PropertyListEncoder().encode(snapshot) else { return }
        UserDefaults(suiteName: appGroupId)?.set(data, forKey: storageKey)
    }
}
