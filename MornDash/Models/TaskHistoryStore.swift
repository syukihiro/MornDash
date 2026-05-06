import Foundation

/// タスクごとの完了履歴を保存するストア。
///
/// 設計メモ:
/// - キーは `TaskItem.id` (UUID)。タスクが削除されても履歴は残し、`nameSnapshots` 経由で名前を復元できる。
/// - 同日内の複数 record は単一日として保持する（toggle off→on を二重計上しない）。
/// - `targetReps` / 秒数は履歴側に持たない。集計時に **現在の TaskItem の値** を使う方針（プランの判断ポイント参照）。
struct TaskHistoryStore: Codable {
    private(set) var datesByTask: [UUID: [Date]]
    private(set) var nameSnapshots: [UUID: String]

    private static let saveKey = "mornDash_task_history"

    init(datesByTask: [UUID: [Date]] = [:], nameSnapshots: [UUID: String] = [:]) {
        self.datesByTask = datesByTask
        self.nameSnapshots = nameSnapshots
    }

    static func load() -> TaskHistoryStore {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode(TaskHistoryStore.self, from: data) {
            return decoded
        }
        return TaskHistoryStore()
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.saveKey)
        }
    }

    /// 指定タスクの「今日の」完了を記録する。同日に既に記録があれば何もしない。
    mutating func record(taskId: UUID, title: String) {
        let today = Calendar.current.startOfDay(for: Date())
        var dates = datesByTask[taskId] ?? []
        if !dates.contains(where: { Calendar.current.isDate($0, inSameDayAs: today) }) {
            dates.append(today)
            dates.sort()
            datesByTask[taskId] = dates
        }
        nameSnapshots[taskId] = title
    }

    enum Period {
        case currentMonth, lastMonth
        case currentYear, lastYear
    }

    func count(taskId: UUID, in period: Period) -> Int {
        guard let dates = datesByTask[taskId], let interval = dateInterval(for: period) else { return 0 }
        return dates.filter { interval.contains($0) }.count
    }

    /// 指定期間内に存在する暦日数（今月なら今月の経過日数、今年なら今年の経過日数）。
    /// 達成率の分母として使う。
    func calendarDayCount(in period: Period) -> Int {
        guard let interval = dateInterval(for: period) else { return 0 }
        let cal = Calendar.current
        let now = Date()
        let endCap = min(interval.end, now)
        guard endCap > interval.start else { return 0 }
        let startDay = cal.startOfDay(for: interval.start)
        let endDay = cal.startOfDay(for: endCap)
        let days = cal.dateComponents([.day], from: startDay, to: endDay).day ?? 0
        return max(1, days + 1)
    }

    /// 直近 7 日 (古い→新しい) の (日付, タスクが完了したか) を返す。
    func recentSevenDays(taskId: UUID) -> [(date: Date, completed: Bool)] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let dates = datesByTask[taskId] ?? []
        return (0..<7).reversed().compactMap { offset in
            guard let day = cal.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let completed = dates.contains { cal.isDate($0, inSameDayAs: day) }
            return (day, completed)
        }
    }

    func snapshotName(for taskId: UUID) -> String? {
        nameSnapshots[taskId]
    }

    private func dateInterval(for period: Period) -> DateInterval? {
        let cal = Calendar.current
        let now = Date()
        switch period {
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
        }
    }
}
