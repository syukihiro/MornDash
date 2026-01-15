import Foundation

struct AlarmSettings: Codable, Identifiable {
    var id: UUID = UUID()
    var isEnabled: Bool
    var time: Date
    var soundName: String = "Classic" // 追加: 選択されたサウンド名
    var selectedWeekdays: Set<Int>
    var blockDurationMinutes: Int = 3 // ブロック時間（分）
    var windDownDurationMinutes: Int = 3 // おやすみ前のブロック時間（分）
    var lastRingDate: Date? // 最後にアラームが鳴った日時

    
    // デフォルト設定
    static var defaultSettings: AlarmSettings {
        var components = DateComponents()
        components.hour = 7
        components.minute = 0
        let defaultTime = Calendar.current.date(from: components) ?? Date()
        
        return AlarmSettings(
            isEnabled: true,
            time: defaultTime,
            soundName: "Classic", // 初期値
            selectedWeekdays: [],
            blockDurationMinutes: 3,
            windDownDurationMinutes: 3,
            lastRingDate: nil
        )
    }
    
    // 永続化用のキー
    private static let tempSaveKey = "mornDash_alarm_settings"
    
    // 保存
    func save() {
        if let encoded = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(encoded, forKey: Self.tempSaveKey)
        }
    }
    
    // 読み込み
    static func load() -> AlarmSettings {
        if let data = UserDefaults.standard.data(forKey: tempSaveKey),
           let decoded = try? JSONDecoder().decode(AlarmSettings.self, from: data) {
            return decoded
        }
        return defaultSettings
    }
}
