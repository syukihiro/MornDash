import Foundation

/// ルーティン完了ストリークの節目ごとに一度だけ App Store 評価リクエストを出すための記録。
enum ReviewPromptStore {
    static let milestones: Set<Int> = [3, 7, 30]

    private static let promptedKey = "mornDash_reviewPromptedMilestones"

    /// この streak で評価を求めるべきならその節目を返す。過去に表示済みなら nil。
    static func milestoneToPrompt(forStreak streak: Int) -> Int? {
        guard milestones.contains(streak) else { return nil }
        let prompted = UserDefaults.standard.array(forKey: promptedKey) as? [Int] ?? []
        return prompted.contains(streak) ? nil : streak
    }

    static func markPrompted(_ milestone: Int) {
        var prompted = UserDefaults.standard.array(forKey: promptedKey) as? [Int] ?? []
        guard !prompted.contains(milestone) else { return }
        prompted.append(milestone)
        UserDefaults.standard.set(prompted, forKey: promptedKey)
    }
}
