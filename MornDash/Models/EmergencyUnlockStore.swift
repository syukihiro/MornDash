import Foundation

struct EmergencyUnlockStore: Codable {
    private(set) var unlockDates: [Date]

    private static let saveKey = "mornDash_emergency_unlock_store"

    static func load() -> EmergencyUnlockStore {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode(EmergencyUnlockStore.self, from: data) {
            return decoded
        }
        return EmergencyUnlockStore(unlockDates: [])
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.saveKey)
        }
    }

    mutating func record(at date: Date = Date()) {
        unlockDates.append(date)
        unlockDates.sort()
    }

    var totalCount: Int { unlockDates.count }

    var thisMonthCount: Int {
        let cal = Calendar.current
        guard let monthStart = cal.dateInterval(of: .month, for: Date())?.start else { return 0 }
        return unlockDates.filter { $0 >= monthStart }.count
    }

    var thisWeekCount: Int {
        let cal = Calendar.current
        guard let weekStart = cal.dateInterval(of: .weekOfYear, for: Date())?.start else { return 0 }
        return unlockDates.filter { $0 >= weekStart }.count
    }

    var lastUnlockDate: Date? { unlockDates.last }
}
