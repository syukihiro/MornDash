import Foundation
import FamilyControls

enum SharedStorage {
    static let appGroup = "group.danchi.MornDash"

    enum Keys {
        static let selection = "blockSelection"
        static let startHour = "startHour"
        static let startMinute = "startMinute"
        static let lastGiveUpDate = "lastGiveUpDate"
        static let taskSnapshot = "taskSnapshot"
        static let shieldAttemptState = "shieldAttemptState"
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

    // MARK: - Task snapshot (シールド拡張が「今日の残りタスク」を表示するためのミラー)

    /// タイトルと最終完了日だけの軽量コピー。「今日完了済みか」は読む側が判定するので、
    /// 日付が変わってもミラーが古くならない。
    struct TaskSnapshot: Codable {
        var title: String
        var lastCompletedDate: Date?

        var isCompletedToday: Bool {
            guard let date = lastCompletedDate else { return false }
            return Calendar.current.isDateInToday(date)
        }
    }

    static func saveTaskSnapshot(_ snapshots: [TaskSnapshot]) {
        if let data = try? JSONEncoder().encode(snapshots) {
            defaults.set(data, forKey: Keys.taskSnapshot)
        }
    }

    static func loadTaskSnapshot() -> [TaskSnapshot] {
        guard let data = defaults.data(forKey: Keys.taskSnapshot),
              let snapshots = try? JSONDecoder().decode([TaskSnapshot].self, from: data) else {
            return []
        }
        return snapshots
    }

    // MARK: - Shield attempts (今日ブロック画面を出した=開こうとした回数、アプリごと)

    private struct ShieldAttemptState: Codable {
        var date: Date = Date()
        /// アプリ(バンドルID)ごとの今日の回数
        var counts: [String: Int] = [:]
        /// アプリごとの直近加算時刻(二重レンダリングのデバウンス用)
        var lastIncrement: [String: Date] = [:]
    }

    private static func loadShieldAttemptState() -> ShieldAttemptState {
        guard let data = defaults.data(forKey: Keys.shieldAttemptState),
              let state = try? JSONDecoder().decode(ShieldAttemptState.self, from: data),
              Calendar.current.isDateInToday(state.date) else {
            return ShieldAttemptState()
        }
        return state
    }

    static func shieldAttemptsToday(for key: String) -> Int {
        loadShieldAttemptState().counts[key] ?? 0
    }

    /// そのアプリの1回分をカウントして今日の合計を返す。日付が変わっていたら数え直す。
    /// シールド1回の表示で configuration が複数回呼ばれるため、直近数秒内の連続呼び出しは同じ1回として扱う。
    @discardableResult
    static func incrementShieldAttemptsToday(for key: String) -> Int {
        let now = Date()
        var state = loadShieldAttemptState()
        if let last = state.lastIncrement[key], now.timeIntervalSince(last) < 3 {
            return state.counts[key] ?? 0
        }
        state.date = now
        state.lastIncrement[key] = now
        state.counts[key] = (state.counts[key] ?? 0) + 1
        if let data = try? JSONEncoder().encode(state) {
            defaults.set(data, forKey: Keys.shieldAttemptState)
        }
        return state.counts[key] ?? 0
    }
}
