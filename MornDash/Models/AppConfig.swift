import Foundation

struct AppConfig: Codable {
    var startHour: Int = 7
    var startMinute: Int = 0

    private static let saveKey = "mornDash_app_config"

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
