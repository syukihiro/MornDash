import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    // 通知の許可をリクエスト (Async)
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
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
    
    // アラーム通知をスケジュール
    func scheduleAlarm(at date: Date) {
        // 既存の通知をクリア
        cancelAlarm()
        
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("notification_title", comment: "")
        content.body = NSLocalizedString("notification_body_main", comment: "")
        // カスタムサウンドを使用 (SoundManagerで生成した Library/Sounds/alarm_sound.wav)
        content.sound = UNNotificationSound(named: UNNotificationSoundName("alarm_sound.wav"))
        
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }
        
        // トリガー作成 (メインのアラーム)
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
        // iOSはアプリが起動しない限り音を止められないため、ユーザーが起きるまで
        // 1分おきに通知を送り続ける（計5回など）
        scheduleBackupNotifications(at: date, count: 5)
    }
    
    // バックアップ通知のスケジュール
    private func scheduleBackupNotifications(at date: Date, count: Int) {
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("notification_title", comment: "")
        content.body = NSLocalizedString("notification_body_backup", comment: "")
        content.sound = UNNotificationSound(named: UNNotificationSoundName("alarm_sound.wav"))
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }
        
        let calendar = Calendar.current
        _ = calendar.dateComponents([.hour, .minute], from: date)
        
        for i in 1...count {
            // 時間を1分ずつずらす
            // 注意: 単純な加算だと日付またぎなどでバグる可能性があるが、毎日繰り返しアラームの場合は
            // DateComponentsでhour/minuteを指定するのが基本。
            // ここでは簡易的に、Dateに分を加算してComponentsを取り直す
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
        let backupIds = (1...10).map { "MORNDASH_ALARM_BACKUP_\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: backupIds)
        
        print("Alarm notification canceled")
    }
}
