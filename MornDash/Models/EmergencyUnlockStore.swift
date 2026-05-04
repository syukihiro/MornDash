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

    enum CountPeriod {
        case currentWeek, lastWeek
        case currentMonth, lastMonth
        case currentYear, lastYear
        /// 今日から遡って 365 日。
        case pastYear
        case total
    }

    func count(_ period: CountPeriod) -> Int {
        if period == .total { return unlockDates.count }
        guard let interval = dateInterval(for: period) else { return 0 }
        return unlockDates.filter { interval.contains($0) }.count
    }

    private func dateInterval(for period: CountPeriod) -> DateInterval? {
        let cal = Calendar.current
        let now = Date()
        switch period {
        case .currentWeek:
            return cal.dateInterval(of: .weekOfYear, for: now)
        case .lastWeek:
            guard let thisWeek = cal.dateInterval(of: .weekOfYear, for: now),
                  let prev = cal.date(byAdding: .day, value: -1, to: thisWeek.start) else { return nil }
            return cal.dateInterval(of: .weekOfYear, for: prev)
        case .currentMonth:
            return cal.dateInterval(of: .month, for: now)
        case .lastMonth:
            guard let thisMonth = cal.dateInterval(of: .month, for: now),
                  let prev = cal.date(byAdding: .day, value: -1, to: thisMonth.start) else { return nil }
            return cal.dateInterval(of: .month, for: prev)
        case .currentYear:
            return cal.dateInterval(of: .year, for: now)
        case .lastYear:
            guard let thisYear = cal.dateInterval(of: .year, for: now),
                  let prev = cal.date(byAdding: .day, value: -1, to: thisYear.start) else { return nil }
            return cal.dateInterval(of: .year, for: prev)
        case .pastYear:
            let end = cal.startOfDay(for: now)
            guard let start = cal.date(byAdding: .day, value: -365, to: end),
                  let endExclusive = cal.date(byAdding: .day, value: 1, to: end) else { return nil }
            return DateInterval(start: start, end: endExclusive)
        case .total:
            return nil
        }
    }

    var lastUnlockDate: Date? { unlockDates.last }
}
