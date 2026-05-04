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
    @Published var currentTime: Date = Date()
    @Published var pendingBadge: Badge?

    private var pendingBadgeQueue: [Badge] = []
    private var cancellables = Set<AnyCancellable>()

    init() {
        self.config = AppConfig.load()
        self.taskStore = TaskStore.load()
        self.streakStore = StreakStore.load()
        self.emergencyUnlockStore = EmergencyUnlockStore.load()
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

    /// 現在時刻 >= 開始時刻(同日内) なら true
    var isInBlockWindow: Bool {
        let calendar = Calendar.current
        let now = currentTime
        let weekday = calendar.component(.weekday, from: now)
        let (h, m) = effectiveStartTime(forWeekday: weekday)
        let startComponents = DateComponents(
            year: calendar.component(.year, from: now),
            month: calendar.component(.month, from: now),
            day: calendar.component(.day, from: now),
            hour: h,
            minute: m
        )
        guard let start = calendar.date(from: startComponents) else { return false }
        return now >= start
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
        taskStore.toggle(id)
        if taskStore.allCompletedToday {
            if !wasAllCompleted {
                streakStore.recordCompletionToday()
                let newlyUnlocked = streakStore.newlyUnlockedBadges()
                if !newlyUnlocked.isEmpty {
                    pendingBadgeQueue.append(contentsOf: newlyUnlocked)
                    presentNextBadgeIfNeeded()
                }
            }
            blockManager.clearShield()
        }
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

    func giveUp(blockManager: BlockManager) {
        SharedStorage.defaults.set(Date(), forKey: SharedStorage.Keys.lastGiveUpDate)
        emergencyUnlockStore.record()
        blockManager.clearShield()
        objectWillChange.send()
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
