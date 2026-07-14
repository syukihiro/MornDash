import Foundation
import Combine

enum AppState {
    case idle       // 開始時間前、またはタスク完了済み
    case blocking   // ブロック中(タスク未完了)
}

class HomeViewModel: ObservableObject {
    @Published var config: AppConfig
    @Published var taskStore: TaskStore
    @Published var streakStore: StreakStore
    @Published var emergencyUnlockStore: EmergencyUnlockStore
    @Published var taskHistoryStore: TaskHistoryStore
    @Published var currentTime: Date = Date()
    @Published var pendingBadge: Badge?
    @Published var showRoutineCompleteCelebration = false
    @Published var routineCelebrationStyle: RoutineCelebrationStyle = .full
    @Published var celebrationBadge: Badge?

    private var pendingBadgeQueue: [Badge] = []
    private var badgesUnlockedThisCompletion: [Badge] = []
    private var reviewMilestonePending: Int?
    private var cancellables = Set<AnyCancellable>()

    init() {
        self.config = AppConfig.load()
        self.taskStore = TaskStore.load()
        self.streakStore = StreakStore.load()
        self.emergencyUnlockStore = EmergencyUnlockStore.load()
        self.taskHistoryStore = TaskHistoryStore.load()
        setupSubscriptions()
        startTimer()
    }

    private func setupSubscriptions() {
        $config
            .dropFirst()
            .debounce(for: 0.3, scheduler: RunLoop.main)
            .sink { settings in settings.save() }
            .store(in: &cancellables)

        $taskStore
            .dropFirst()
            .debounce(for: 0.3, scheduler: RunLoop.main)
            .sink { store in store.save() }
            .store(in: &cancellables)

        $streakStore
            .dropFirst()
            .debounce(for: 0.3, scheduler: RunLoop.main)
            .sink { store in store.save() }
            .store(in: &cancellables)

        $emergencyUnlockStore
            .dropFirst()
            .debounce(for: 0.3, scheduler: RunLoop.main)
            .sink { store in store.save() }
            .store(in: &cancellables)

        $taskHistoryStore
            .dropFirst()
            .debounce(for: 0.3, scheduler: RunLoop.main)
            .sink { store in store.save() }
            .store(in: &cancellables)
    }

    private func startTimer() {
        Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.currentTime = Date()
            }
            .store(in: &cancellables)
    }

    var appState: AppState {
        if isInBlockWindow && !taskStore.allCompletedToday && !hasGivenUpToday {
            return .blocking
        }
        return .idle
    }

    /// 現在時刻が開始〜23:59 のブロック窓内なら true（Monitor 拡張の intervalEnd と一致）
    var isInBlockWindow: Bool {
        let calendar = Calendar.current
        let now = currentTime
        let weekday = calendar.component(.weekday, from: now)
        let (h, m) = effectiveStartTime(forWeekday: weekday)
        return BlockWindowLogic.isInBlockWindow(now: now, startHour: h, startMinute: m, calendar: calendar)
    }

    private func effectiveStartTime(forWeekday weekday: Int) -> (hour: Int, minute: Int) {
        if SubscriptionManager.shared.isPro && config.weekdaySchedulingEnabled {
            return config.startTime(for: weekday)
        }
        return (config.startHour, config.startMinute)
    }

    var hasGivenUpToday: Bool {
        guard let rawDate = SharedStorage.defaults.object(forKey: SharedStorage.Keys.lastGiveUpDate) as? Date else {
            return false
        }
        return Calendar.current.isDateInToday(rawDate)
    }

    // MARK: - Actions

    func toggleTask(_ id: UUID, blockManager: BlockManager) {
        let wasAllCompleted = taskStore.allCompletedToday
        let wasCompletedTask = taskStore.tasks.first(where: { $0.id == id })?.isCompletedToday ?? false
        taskStore.toggle(id)
        if !wasCompletedTask, let task = taskStore.tasks.first(where: { $0.id == id }), task.isCompletedToday {
            taskHistoryStore.record(taskId: task.id, title: task.title)
        }
        if taskStore.allCompletedToday {
            if !wasAllCompleted {
                streakStore.recordCompletionToday()
                recordTodaysBlockedDuration()
                let streak = streakStore.currentStreak
                AnalyticsService.logRoutineCompleted(
                    streak: streak,
                    isFirstEver: streakStore.totalCompleted == 1
                )
                routineCelebrationStyle = RoutineCelebrationStyle.forCompletion(
                    streak: streak,
                    isFirstCompletionEver: streakStore.totalCompleted == 1
                )
                let newlyUnlocked = streakStore.newlyUnlockedBadges()
                badgesUnlockedThisCompletion = newlyUnlocked
                celebrationBadge = newlyUnlocked.first
                showRoutineCompleteCelebration = true
                reviewMilestonePending = ReviewPromptStore.milestoneToPrompt(forStreak: streak)
            }
            blockManager.clearShield()
        }
    }

    func dismissRoutineCompleteCelebration() {
        showRoutineCompleteCelebration = false
        for badge in badgesUnlockedThisCompletion {
            streakStore.markCelebrated(threshold: badge.threshold)
        }
        badgesUnlockedThisCompletion = []
        celebrationBadge = nil
        presentNextBadgeIfNeeded()
    }

    func dismissPendingBadge() {
        if let current = pendingBadge {
            streakStore.markCelebrated(threshold: current.threshold)
        }
        pendingBadge = nil
        presentNextBadgeIfNeeded()
    }

    private func presentNextBadgeIfNeeded() {
        guard pendingBadge == nil, !pendingBadgeQueue.isEmpty else { return }
        pendingBadge = pendingBadgeQueue.removeFirst()
    }

    /// セレブレーションがすべて閉じた後に呼ぶ。評価リクエストを出すべき節目なら一度だけその値を返す。
    func consumeReviewPromptIfReady() -> Int? {
        guard !showRoutineCompleteCelebration, pendingBadge == nil,
              let milestone = reviewMilestonePending else { return nil }
        reviewMilestonePending = nil
        ReviewPromptStore.markPrompted(milestone)
        return milestone
    }

    func giveUp(blockManager: BlockManager) {
        AnalyticsService.logGiveUp(streak: streakStore.currentStreak)
        SharedStorage.defaults.set(Date(), forKey: SharedStorage.Keys.lastGiveUpDate)
        emergencyUnlockStore.record()
        recordTodaysBlockedDuration()
        blockManager.clearShield()
        objectWillChange.send()
    }

    /// 今日の開始時刻から現在までの経過秒を StreakStore に記録する。
    /// 開始時刻前なら何もしない（その日はブロックが発生していない）。
    private func recordTodaysBlockedDuration() {
        guard let start = todayStartDate() else { return }
        let now = Date()
        guard now >= start else { return }
        streakStore.recordBlockedDurationToday(now.timeIntervalSince(start))
    }

    private func todayStartDate() -> Date? {
        let cal = Calendar.current
        let now = Date()
        let weekday = cal.component(.weekday, from: now)
        let (h, m) = effectiveStartTime(forWeekday: weekday)
        return cal.date(from: DateComponents(
            year: cal.component(.year, from: now),
            month: cal.component(.month, from: now),
            day: cal.component(.day, from: now),
            hour: h,
            minute: m
        ))
    }

    /// メインアプリが前面に出たとき、現在ブロック窓内ならシールドを適用(冗長だが安全網)。
    func syncShield(blockManager: BlockManager) {
        if appState == .blocking {
            blockManager.applyShield()
        } else {
            blockManager.clearShield()
        }
    }

    func applySchedule(blockManager: BlockManager) {
        if SubscriptionManager.shared.isPro && config.weekdaySchedulingEnabled {
            blockManager.scheduleWeekdayBlocks(config.weekdayStartTimes)
        } else {
            blockManager.scheduleDailyBlock(startHour: config.startHour, startMinute: config.startMinute)
        }
    }
}
