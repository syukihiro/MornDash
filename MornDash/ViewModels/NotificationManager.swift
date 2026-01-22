import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    // 通知の許可をリクエスト
    func requestAuthorization() async -> Bool {
        do {
            // .timeSensitive をオプションに追加
            let options: UNAuthorizationOptions = [.alert, .sound, .badge] // iOS 15以降は.timeSensitiveも含められるが、Entitlementsがあれば通常は機能する
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: options)
            return granted
        } catch {
            print("Notification permission error: \(error.localizedDescription)")
            return false
        }
    }
    
    // 通知の許可をリクエスト (Legacy)
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission denied: \(error.localizedDescription)")
            }
        }
    }
    
    // アラームをスケジュール
    func scheduleAlarm(at date: Date) {
        // 既存のアラームを削除
        cancelAlarm()
        
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("notification_title", comment: "Alarm")
        content.body = NSLocalizedString("notification_body_main", comment: "Time to wake up!")
        
        // サウンド設定
        // 現在設定されているサウンド情報を取得
        let soundName = AlarmSettings.load().soundName
        let selectedSound = AlarmSound.all.first(where: { $0.name == soundName }) ?? AlarmSound.defaultSound
        
        if let systemName = selectedSound.systemSoundName {
            // システムサウンド名が指定されている場合（※ファイルがバンドル内に必要）
            // "Radar.caf" などのファイルを用意してプロジェクトに入れる必要があります
            // ここではファイル拡張子を補完するロジックなどを入れるか、そのまま指定
            content.sound = UNNotificationSound(named: UNNotificationSoundName("\(systemName).caf"))
        } else {
            // カスタム生成サウンド (Library/Sounds/alarm_sound.wav)
            content.sound = UNNotificationSound(named: UNNotificationSoundName("alarm_sound.wav"))
        }
        
        // Time Sensitive (即時通知) 設定
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }
        
        // トリガー作成
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(identifier: "MORNDASH_ALARM", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Alarm scheduled for \(components.hour!):\(components.minute!)")
            }
        }
        
        // バックアップ通知（スヌーズ的な連続通知）をセット
        // アプリが起動しない限り音を止められないように、1分おきに通知を送る
        scheduleBackupNotifications(at: date, count: 10, soundName: systemNameOrCustom(selectedSound))
    }
    
    private func systemNameOrCustom(_ sound: AlarmSound) -> String {
        if let sys = sound.systemSoundName {
            return "\(sys).caf"
        }
        return "alarm_sound.wav"
    }
    
    // バックアップ通知のスケジュール
    private func scheduleBackupNotifications(at date: Date, count: Int, soundName: String) {
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("notification_title", comment: "")
        content.body = NSLocalizedString("notification_body_backup", comment: "")
        content.sound = UNNotificationSound(named: UNNotificationSoundName(soundName))
        
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }
        
        let calendar = Calendar.current
        
        for i in 1...count {
            if let nextDate = calendar.date(byAdding: .minute, value: i, to: date) {
                let nextComponents = calendar.dateComponents([.hour, .minute], from: nextDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: nextComponents, repeats: true)
                let id = "MORNDASH_ALARM_BACKUP_\(i)"
                
                let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request)
            }
        }
    }
    
    // アラーム通知をキャンセル
    func cancelAlarm() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["MORNDASH_ALARM"])
        
        // バックアップ通知も削除
        let backupIds = (1...20).map { "MORNDASH_ALARM_BACKUP_\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: backupIds)
        
        print("Alarm notification canceled")
    }
}
