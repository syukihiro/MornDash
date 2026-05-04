import Foundation

struct WeekdayTime: Codable, Equatable {
    var hour: Int
    var minute: Int
}

struct AppConfig: Codable {
    var startHour: Int = 7
    var startMinute: Int = 0
    var weekdaySchedulingEnabled: Bool = false
    var weekdayStartTimes: [WeekdayTime] = AppConfig.defaultWeekdayTimes()

    private static let saveKey = "mornDash_app_config"

    static func defaultWeekdayTimes() -> [WeekdayTime] {
        Array(repeating: WeekdayTime(hour: 7, minute: 0), count: 7)
    }

    enum CodingKeys: String, CodingKey {
        case startHour, startMinute, weekdaySchedulingEnabled, weekdayStartTimes
    }

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.startHour = (try? c.decode(Int.self, forKey: .startHour)) ?? 7
        self.startMinute = (try? c.decode(Int.self, forKey: .startMinute)) ?? 0
        self.weekdaySchedulingEnabled = (try? c.decode(Bool.self, forKey: .weekdaySchedulingEnabled)) ?? false
        let times = (try? c.decode([WeekdayTime].self, forKey: .weekdayStartTimes)) ?? Self.defaultWeekdayTimes()
        self.weekdayStartTimes = times.count == 7 ? times : Self.defaultWeekdayTimes()
    }

    /// weekday is Calendar.weekday (1 = Sunday ... 7 = Saturday).
    func startTime(for weekday: Int) -> (hour: Int, minute: Int) {
        let idx = max(0, min(6, weekday - 1))
        if weekdaySchedulingEnabled, idx < weekdayStartTimes.count {
            let t = weekdayStartTimes[idx]
            return (t.hour, t.minute)
        }
        return (startHour, startMinute)
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.saveKey)
        }
        // Mirror to App Group so the DeviceActivityMonitor extension can read it.
        SharedStorage.defaults.set(startHour, forKey: SharedStorage.Keys.startHour)
        SharedStorage.defaults.set(startMinute, forKey: SharedStorage.Keys.startMinute)
    }

    static func load() -> AppConfig {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode(AppConfig.self, from: data) {
            return decoded
        }
        return AppConfig()
    }
}
