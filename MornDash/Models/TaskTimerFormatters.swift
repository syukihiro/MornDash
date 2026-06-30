import Foundation

enum TaskTimerFormatters {
    static let maxMinutes = 180
    static let maxTotalSeconds = maxMinutes * 60

    static func split(seconds: Int) -> (minutes: Int, seconds: Int) {
        let clamped = max(seconds, 0)
        return (clamped / 60, clamped % 60)
    }

    static func totalSeconds(minutes: Int, seconds: Int) -> Int? {
        guard minutes >= 0, seconds >= 0, seconds <= 59 else { return nil }
        let total = minutes * 60 + seconds
        guard total > 0, total <= maxTotalSeconds else { return nil }
        return total
    }

    /// 分・秒の入力文字列から合計秒数を返す。無効なら nil。
    static func totalSeconds(minutesInput: String, secondsInput: String) -> Int? {
        totalSeconds(minutes: Int(minutesInput) ?? 0, seconds: Int(secondsInput) ?? 0)
    }

    static func durationLabel(seconds: Int) -> String {
        let (minutes, secs) = split(seconds: seconds)
        switch (minutes, secs) {
        case (0, let s):
            return String(format: NSLocalizedString("tasks_timer_seconds_short_format", comment: ""), s)
        case (let m, 0):
            return String(format: NSLocalizedString("tasks_timer_minutes_short_format", comment: ""), m)
        default:
            return String(format: NSLocalizedString("tasks_timer_duration_min_sec_format", comment: ""), minutes, secs)
        }
    }
}
