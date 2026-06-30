import Foundation

struct StreakStore: Codable {
    private(set) var completionDates: [Date]
    private(set) var celebratedThresholds: Set<Int>
    private(set) var blockedSecondsByDay: [Date: TimeInterval]

    private static let saveKey = "mornDash_streak_store"

    private enum CodingKeys: String, CodingKey {
        case completionDates
        case celebratedThresholds
        case blockedSecondsByDay
    }

    init(
        completionDates: [Date] = [],
        celebratedThresholds: Set<Int> = [],
        blockedSecondsByDay: [Date: TimeInterval] = [:]
    ) {
        self.completionDates = completionDates
        self.celebratedThresholds = celebratedThresholds
        self.blockedSecondsByDay = blockedSecondsByDay
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let dates = try c.decode([Date].self, forKey: .completionDates)
        self.blockedSecondsByDay = (try? c.decodeIfPresent([Date: TimeInterval].self, forKey: .blockedSecondsByDay)) ?? [:]
        if let stored = try c.decodeIfPresent(Set<Int>.self, forKey: .celebratedThresholds) {
            self.completionDates = dates
            self.celebratedThresholds = stored
        } else {
            // 既存ユーザーのマイグレーション: 過去に到達済みのバッジは演出済みとして埋める。
            self.completionDates = dates
            self.celebratedThresholds = []
            let alreadyReached = Badge.thresholds.filter { $0 <= self.longestStreak }
            self.celebratedThresholds = Set(alreadyReached)
        }
    }

    static func load() -> StreakStore {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode(StreakStore.self, from: data) {
            return decoded
        }
        return StreakStore()
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.saveKey)
        }
    }

    mutating func recordCompletionToday() {
        let today = Calendar.current.startOfDay(for: Date())
        if !completionDates.contains(where: { Calendar.current.isDate($0, inSameDayAs: today) }) {
            completionDates.append(today)
            completionDates.sort()
        }
    }

    /// 今日のブロック継続時間を記録する。シールドが解除された瞬間（タスク全完了 or 緊急解除）に呼ばれる想定。
    /// 同日内に複数回呼ばれても、最初に記録された値を保持する（解除→再ロック→再解除の二重計上を避けるため）。
    mutating func recordBlockedDurationToday(_ seconds: TimeInterval) {
        let key = Calendar.current.startOfDay(for: Date())
        if blockedSecondsByDay[key] == nil {
            blockedSecondsByDay[key] = max(0, seconds)
        }
    }

    enum BlockedDurationPeriod {
        case currentWeek, lastWeek
        case currentMonth, lastMonth
        case currentYear, lastYear
        /// 今日から遡って 365 日。
        case pastYear
    }

    /// 指定期間内の「記録された日」だけを母数にした平均ブロック継続秒数。
    /// 設定していない日でゼロ割りされないよう、母数は entry 数（記録のある日）に限定する。
    func averageBlockedSeconds(_ period: BlockedDurationPeriod) -> TimeInterval {
        guard let interval = dateInterval(for: period) else { return 0 }
        let entries = blockedSecondsByDay.filter { interval.contains($0.key) }
        guard !entries.isEmpty else { return 0 }
        return entries.values.reduce(0, +) / TimeInterval(entries.count)
    }

    private func dateInterval(for period: BlockedDurationPeriod) -> DateInterval? {
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
            guard let start = cal.date(byAdding: .day, value: -365, to: end) else { return nil }
            // end は今日の00:00。今日のデータも含めるため end を翌日0時にする。
            guard let endExclusive = cal.date(byAdding: .day, value: 1, to: end) else { return nil }
            return DateInterval(start: start, end: endExclusive)
        }
    }

    /// `longestStreak` で新たに閾値を超えた、まだ演出していないバッジを返す。
    /// 戻り値は閾値の小さい順（複数同時アンロック時の表示順）。
    func newlyUnlockedBadges() -> [Badge] {
        let longest = longestStreak
        return Badge.all.filter { longest >= $0.threshold && !celebratedThresholds.contains($0.threshold) }
    }

    mutating func markCelebrated(threshold: Int) {
        celebratedThresholds.insert(threshold)
    }

    var isCompletedToday: Bool {
        let cal = Calendar.current
        return completionDates.contains { cal.isDateInToday($0) }
    }

    var currentStreak: Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        guard let yesterday = cal.date(byAdding: .day, value: -1, to: today) else { return 0 }

        let sorted = completionDates.sorted(by: >)
        guard let mostRecent = sorted.first else { return 0 }

        let startsToday = cal.isDate(mostRecent, inSameDayAs: today)
        let startsYesterday = cal.isDate(mostRecent, inSameDayAs: yesterday)
        guard startsToday || startsYesterday else { return 0 }

        var streak = 0
        var expected = startsToday ? today : yesterday
        for date in sorted {
            if cal.isDate(date, inSameDayAs: expected) {
                streak += 1
                guard let prev = cal.date(byAdding: .day, value: -1, to: expected) else { break }
                expected = prev
            } else {
                break
            }
        }
        return streak
    }

    var longestStreak: Int {
        guard !completionDates.isEmpty else { return 0 }
        let cal = Calendar.current
        let sorted = completionDates.map { cal.startOfDay(for: $0) }.sorted()

        var maxRun = 1
        var run = 1
        for i in 1..<sorted.count {
            let diff = cal.dateComponents([.day], from: sorted[i - 1], to: sorted[i]).day ?? 0
            if diff == 1 {
                run += 1
                maxRun = max(maxRun, run)
            } else if diff > 1 {
                run = 1
            }
        }
        return maxRun
    }

    var completedThisWeek: Int {
        let cal = Calendar.current
        guard let weekStart = cal.dateInterval(of: .weekOfYear, for: Date())?.start else { return 0 }
        return completionDates.filter { $0 >= weekStart }.count
    }

    var totalCompleted: Int { completionDates.count }

    /// 直近 N 日の (日付, 達成したか) を古い順で返す。
    func recentDays(_ count: Int) -> [(date: Date, completed: Bool)] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let days: [(Date, Bool)] = (0..<count).compactMap { offset in
            guard let date = cal.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let completed = completionDates.contains { cal.isDate($0, inSameDayAs: date) }
            return (date, completed)
        }
        return days.reversed()
    }

    struct ContributionDay {
        let date: Date
        let completed: Bool
        let isFuture: Bool
    }

    struct MonthCalendarDay {
        let date: Date
        let day: Int
        let isInMonth: Bool
        let completed: Bool
        let isFuture: Bool
        let isToday: Bool
    }

    /// 今月のカレンダーグリッド用。先頭の空白埋めを含む 7 の倍数の日セルを返す。
    func monthCalendar(reference: Date = Date()) -> [MonthCalendarDay] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: reference)
        guard let monthInterval = cal.dateInterval(of: .month, for: today),
              let dayRange = cal.range(of: .day, in: .month, for: today)
        else { return [] }

        let firstOfMonth = cal.startOfDay(for: monthInterval.start)
        let leadingPadding = (cal.component(.weekday, from: firstOfMonth) - cal.firstWeekday + 7) % 7
        let daysInMonth = dayRange.count
        let totalCells = ((leadingPadding + daysInMonth + 6) / 7) * 7

        guard let gridStart = cal.date(byAdding: .day, value: -leadingPadding, to: firstOfMonth) else { return [] }

        return (0..<totalCells).compactMap { offset in
            guard let date = cal.date(byAdding: .day, value: offset, to: gridStart) else { return nil }
            let isInMonth = cal.isDate(date, equalTo: firstOfMonth, toGranularity: .month)
            return MonthCalendarDay(
                date: date,
                day: cal.component(.day, from: date),
                isInMonth: isInMonth,
                completed: completionDates.contains { cal.isDate($0, inSameDayAs: date) },
                isFuture: date > today,
                isToday: cal.isDate(date, inSameDayAs: today)
            )
        }
    }

    /// GitHub 風グリッド用。weeks 列 × 7 行を返す。
    /// 各列は週の開始日（ロケールの `firstWeekday`）から 7 日分。
    /// 最終列は今週、行 0 が週の開始曜日。
    func contributionGrid(weeks: Int) -> [[ContributionDay]] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        let weekday = cal.component(.weekday, from: today)
        let daysFromWeekStart = (weekday - cal.firstWeekday + 7) % 7
        guard let currentWeekStart = cal.date(byAdding: .day, value: -daysFromWeekStart, to: today),
              let gridStart = cal.date(byAdding: .day, value: -7 * (weeks - 1), to: currentWeekStart)
        else { return [] }

        var result: [[ContributionDay]] = []
        for w in 0..<weeks {
            var col: [ContributionDay] = []
            for d in 0..<7 {
                let offset = w * 7 + d
                guard let date = cal.date(byAdding: .day, value: offset, to: gridStart) else { continue }
                let completed = completionDates.contains { cal.isDate($0, inSameDayAs: date) }
                let isFuture = date > today
                col.append(ContributionDay(date: date, completed: completed, isFuture: isFuture))
            }
            result.append(col)
        }
        return result
    }
}
