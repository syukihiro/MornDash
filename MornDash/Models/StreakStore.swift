import Foundation

struct StreakStore: Codable {
    private(set) var completionDates: [Date]
    private(set) var celebratedThresholds: Set<Int>

    private static let saveKey = "mornDash_streak_store"

    private enum CodingKeys: String, CodingKey {
        case completionDates
        case celebratedThresholds
    }

    init(completionDates: [Date] = [], celebratedThresholds: Set<Int> = []) {
        self.completionDates = completionDates
        self.celebratedThresholds = celebratedThresholds
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let dates = try c.decode([Date].self, forKey: .completionDates)
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
