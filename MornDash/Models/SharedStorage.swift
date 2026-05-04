import Foundation
import FamilyControls

enum SharedStorage {
    static let appGroup = "group.danchi.MornDash"

    enum Keys {
        static let selection = "blockSelection"
        static let startHour = "startHour"
        static let startMinute = "startMinute"
        static let lastGiveUpDate = "lastGiveUpDate"
    }

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroup) ?? .standard
    }

    static func saveSelection(_ selection: FamilyActivitySelection) {
        if let data = try? PropertyListEncoder().encode(selection) {
            defaults.set(data, forKey: Keys.selection)
        }
    }

    static func loadSelection() -> FamilyActivitySelection {
        guard let data = defaults.data(forKey: Keys.selection),
              let selection = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data) else {
            return FamilyActivitySelection()
        }
        return selection
    }
}
