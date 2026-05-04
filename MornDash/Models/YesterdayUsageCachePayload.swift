import Foundation
import FamilyControls

/// Duplicated from `MornDashReport/YesterdayUsageCachePayload.swift` — keep keys and fields identical.
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

    static func loadSnapshot() -> Snapshot? {
        guard let data = UserDefaults(suiteName: appGroupId)?.data(forKey: storageKey) else { return nil }
        return try? PropertyListDecoder().decode(Snapshot.self, from: data)
    }
}
