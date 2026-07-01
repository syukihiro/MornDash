import SwiftUI
import DeviceActivity
import FamilyControls

extension DeviceActivityReport.Context {
    static let totalActivity = Self("Total Activity")
    /// Must match `MornDashReport/TotalActivityReport.swift`.
    static let yesterdayUsagePick = Self("Yesterday Usage Pick")
}

struct StatsTabView: View {
    @ObservedObject var viewModel: HomeViewModel
    @ObservedObject var blockManager: BlockManager
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accentTheme) private var accentTheme

    @State private var showPaywall = false
    @State private var taskBreakdownPeriod: TaskHistoryStore.Period = .currentMonth

    var body: some View {
        NavigationStack {
            ZStack {
                MornDashColors.screenBackground(colorScheme).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        StatsStreakSummaryView(
                            streak: viewModel.streakStore.currentStreak,
                            longestStreak: viewModel.streakStore.longestStreak,
                            totalCompleted: viewModel.streakStore.totalCompleted,
                            recentDays: viewModel.streakStore.recentDays(7)
                        )
                        StatsMonthCalendarView(days: viewModel.streakStore.monthCalendar())
                        blockedDurationSection
                        StatsTaskBreakdownSection(
                            history: viewModel.taskHistoryStore,
                            tasks: viewModel.taskStore.tasks,
                            period: $taskBreakdownPeriod
                        )
                        emergencyUnlockSection
                        blockedUsageSection
                        StatsContributionGraphView(weeks: viewModel.streakStore.contributionGrid(weeks: 52))
                        StatsBadgesSectionView(longestStreak: viewModel.streakStore.longestStreak)

                        statsProSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
            }
            .navigationTitle(Text("tab_stats"))
            .mornDashNavigationBarStyle()
            .paywallSheet(isPresented: $showPaywall)
        }
    }

    @ViewBuilder
    private var statsProSection: some View {
        VStack(spacing: 16) {
            if subscriptionManager.isPro {
                StatsSectionHeader(icon: "sparkles", tint: accentTheme.idleColor.opacity(0.85), titleKey: "stats_pro_section_title")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)

                comparisonReportSection
                StatsTaskComparisonSection(
                    history: viewModel.taskHistoryStore,
                    tasks: viewModel.taskStore.tasks,
                    period: taskBreakdownPeriod
                )
                emergencyComparisonReportSection
            } else {
                StatsProUpsellSection(action: { showPaywall = true })
            }
        }
    }

    // MARK: - Blocked duration (per-day averages)

    private var blockedDurationSection: some View {
        let thisWeek = viewModel.streakStore.averageBlockedSeconds(.currentWeek)
        let pastYear = viewModel.streakStore.averageBlockedSeconds(.pastYear)

        return VStack(alignment: .leading, spacing: 12) {
            StatsSectionHeader(icon: "hourglass", tint: accentTheme.blockingColor.opacity(0.85), titleKey: "stats_blocked_duration")

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(StatsFormatters.duration(thisWeek))
                    .font(.system(size: 40, weight: .thin, design: .rounded))
                    .foregroundColor(MornDashColors.labelPrimary(colorScheme))
                Text("stats_blocked_duration_per_day_suffix")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(MornDashColors.labelTertiary(colorScheme))
                Spacer()
                Text("stats_blocked_duration_this_week")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(1)
                    .foregroundColor(MornDashColors.labelTertiary(colorScheme))
            }

            HStack(spacing: 16) {
                blockedDurationMetric(seconds: pastYear, labelKey: "stats_blocked_duration_past_year")
                Spacer()
            }

            if thisWeek == 0 && pastYear == 0 {
                Text("stats_blocked_duration_none")
                    .font(.system(size: 11))
                    .foregroundColor(MornDashColors.labelTertiary(colorScheme))
                    .padding(.top, 2)
            }
        }
        .statsSectionCard(borderColor: accentTheme.blockingColor.opacity(colorScheme == .dark ? 0.12 : 0.18))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func blockedDurationMetric(seconds: TimeInterval, labelKey: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(StatsFormatters.duration(seconds))
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(MornDashColors.labelPrimary(colorScheme, opacity: 0.85))
                Text("stats_blocked_duration_per_day_suffix")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(MornDashColors.labelTertiary(colorScheme))
            }
            Text(LocalizedStringKey(labelKey))
                .font(.system(size: 10, weight: .medium))
                .tracking(1)
                .foregroundColor(MornDashColors.labelTertiary(colorScheme))
        }
    }

    // MARK: - Comparison report (Pro)

    private var comparisonReportSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            StatsSectionHeader(icon: "chart.bar.xaxis", tint: accentTheme.blockingColor.opacity(0.85), titleKey: "stats_blocked_compare")

            comparisonRow(
                current: viewModel.streakStore.averageBlockedSeconds(.currentWeek),
                previous: viewModel.streakStore.averageBlockedSeconds(.lastWeek),
                labelKey: "stats_blocked_compare_week"
            )
            Divider().background(MornDashColors.divider(colorScheme))
            comparisonRow(
                current: viewModel.streakStore.averageBlockedSeconds(.currentMonth),
                previous: viewModel.streakStore.averageBlockedSeconds(.lastMonth),
                labelKey: "stats_blocked_compare_month"
            )
            Divider().background(MornDashColors.divider(colorScheme))
            comparisonRow(
                current: viewModel.streakStore.averageBlockedSeconds(.currentYear),
                previous: viewModel.streakStore.averageBlockedSeconds(.lastYear),
                labelKey: "stats_blocked_compare_year"
            )
        }
        .statsSectionCard()
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func comparisonRow(current: TimeInterval, previous: TimeInterval, labelKey: String) -> some View {
        let delta = StatsFormatters.percentChange(current: current, previous: previous)
        return HStack(alignment: .firstTextBaseline, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(StatsFormatters.duration(current))
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundColor(MornDashColors.labelPrimary(colorScheme, opacity: 0.9))
                Text("stats_blocked_duration_per_day_suffix")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(MornDashColors.labelTertiary(colorScheme))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(LocalizedStringKey(labelKey))
                    .font(.system(size: 10, weight: .medium))
                    .tracking(1)
                    .foregroundColor(MornDashColors.labelTertiary(colorScheme))
                deltaLabel(delta)
            }
        }
    }

    @ViewBuilder
    private func deltaLabel(_ delta: Double?) -> some View {
        if let delta {
            let isUp = delta >= 0
            HStack(spacing: 3) {
                Image(systemName: isUp ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 9, weight: .bold))
                Text(String(format: "%@%.0f%%", isUp ? "+" : "", delta * 100))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
            }
            .foregroundColor(isUp ? .green.opacity(0.85) : .red.opacity(0.75))
        } else {
            Text("stats_blocked_compare_no_baseline")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(MornDashColors.labelMuted(colorScheme))
        }
    }

    // MARK: - Emergency unlocks

    private var emergencyUnlockSection: some View {
        let store = viewModel.emergencyUnlockStore
        let thisWeek = store.count(.currentWeek)
        let thisMonth = store.count(.currentMonth)
        let pastYear = store.count(.pastYear)
        let total = store.count(.total)

        return VStack(alignment: .leading, spacing: 12) {
            StatsSectionHeader(icon: "exclamationmark.triangle.fill", tint: accentTheme.idleColor.opacity(0.85), titleKey: "stats_emergency_unlocks")

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(thisWeek)")
                    .font(.system(size: 40, weight: .thin, design: .rounded))
                    .foregroundColor(MornDashColors.labelPrimary(colorScheme))
                Text("stats_emergency_unlocks_count_unit")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(MornDashColors.labelTertiary(colorScheme))
                Spacer()
                Text("stats_emergency_unlocks_this_week")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(1)
                    .foregroundColor(MornDashColors.labelTertiary(colorScheme))
            }

            HStack(spacing: 16) {
                emergencyUnlockMetric(value: thisMonth, labelKey: "stats_emergency_unlocks_this_month")
                Divider()
                    .frame(height: 28)
                    .background(MornDashColors.progressTrack(colorScheme))
                emergencyUnlockMetric(value: pastYear, labelKey: "stats_emergency_unlocks_past_year")
                Divider()
                    .frame(height: 28)
                    .background(MornDashColors.progressTrack(colorScheme))
                emergencyUnlockMetric(value: total, labelKey: "stats_emergency_unlocks_total")
                Spacer()
            }

            if let last = store.lastUnlockDate {
                Text(String(format: NSLocalizedString("stats_emergency_unlocks_last", comment: ""), StatsFormatters.relativeDate(last)))
                    .font(.system(size: 11))
                    .foregroundColor(MornDashColors.labelTertiary(colorScheme))
                    .padding(.top, 2)
            } else {
                Text("stats_emergency_unlocks_none")
                    .font(.system(size: 11))
                    .foregroundColor(MornDashColors.labelTertiary(colorScheme))
                    .padding(.top, 2)
            }
        }
        .statsSectionCard(borderColor: accentTheme.idleColor.opacity(colorScheme == .dark ? 0.12 : 0.22))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func emergencyUnlockMetric(value: Int, labelKey: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text("\(value)")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(MornDashColors.labelPrimary(colorScheme, opacity: 0.85))
                Text("stats_emergency_unlocks_count_unit")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(MornDashColors.labelTertiary(colorScheme))
            }
            Text(LocalizedStringKey(labelKey))
                .font(.system(size: 10, weight: .medium))
                .tracking(1)
                .foregroundColor(MornDashColors.labelTertiary(colorScheme))
        }
    }

    // MARK: - Emergency unlocks comparison report (Pro)

    private var emergencyComparisonReportSection: some View {
        let store = viewModel.emergencyUnlockStore
        return VStack(alignment: .leading, spacing: 14) {
            StatsSectionHeader(icon: "chart.bar.xaxis", tint: accentTheme.idleColor.opacity(0.85), titleKey: "stats_emergency_compare")

            emergencyComparisonRow(
                current: store.count(.currentWeek),
                previous: store.count(.lastWeek),
                labelKey: "stats_emergency_compare_week"
            )
            Divider().background(MornDashColors.divider(colorScheme))
            emergencyComparisonRow(
                current: store.count(.currentMonth),
                previous: store.count(.lastMonth),
                labelKey: "stats_emergency_compare_month"
            )
            Divider().background(MornDashColors.divider(colorScheme))
            emergencyComparisonRow(
                current: store.count(.currentYear),
                previous: store.count(.lastYear),
                labelKey: "stats_emergency_compare_year"
            )
        }
        .statsSectionCard()
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func emergencyComparisonRow(current: Int, previous: Int, labelKey: String) -> some View {
        let delta = StatsFormatters.percentChange(current: TimeInterval(current), previous: TimeInterval(previous))
        return HStack(alignment: .firstTextBaseline, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text("\(current)")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundColor(MornDashColors.labelPrimary(colorScheme, opacity: 0.9))
                Text("stats_emergency_unlocks_count_unit")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(MornDashColors.labelTertiary(colorScheme))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(LocalizedStringKey(labelKey))
                    .font(.system(size: 10, weight: .medium))
                    .tracking(1)
                    .foregroundColor(MornDashColors.labelTertiary(colorScheme))
                // 緊急解除では「減った=良い」のため delta の色は反転して評価する。
                inverseDeltaLabel(delta)
            }
        }
    }

    /// 減ったほうが良い指標（緊急解除）向けの delta ラベル。
    @ViewBuilder
    private func inverseDeltaLabel(_ delta: Double?) -> some View {
        if let delta {
            let isUp = delta >= 0
            HStack(spacing: 3) {
                Image(systemName: isUp ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 9, weight: .bold))
                Text(String(format: "%@%.0f%%", isUp ? "+" : "", delta * 100))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
            }
            .foregroundColor(isUp ? .red.opacity(0.75) : .green.opacity(0.85))
        } else {
            Text("stats_blocked_compare_no_baseline")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(MornDashColors.labelMuted(colorScheme))
        }
    }

    // MARK: - Blocked apps usage

    private var blockedUsageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("stats_blocked_usage_today")
                .font(.system(size: 11, weight: .medium))
                .tracking(2)
                .foregroundColor(MornDashColors.labelTertiary(colorScheme))

            if selectionIsEmpty {
                Text("stats_blocked_usage_no_selection")
                    .font(.system(size: 13))
                    .foregroundColor(MornDashColors.labelTertiary(colorScheme))
                    .frame(maxWidth: .infinity, minHeight: 60)
            } else {
                #if targetEnvironment(simulator)
                Text(verbatim: "DeviceActivityReport unavailable on simulator")
                    .font(.system(size: 12))
                    .foregroundColor(MornDashColors.labelMuted(colorScheme))
                    .frame(maxWidth: .infinity, minHeight: 280, alignment: .leading)
                #else
                DeviceActivityReport(.totalActivity, filter: todayFilter)
                    .frame(height: 280)
                #endif
            }
        }
        .statsSectionCard()
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var selectionIsEmpty: Bool {
        blockManager.selection.applicationTokens.isEmpty
            && blockManager.selection.categoryTokens.isEmpty
            && blockManager.selection.webDomainTokens.isEmpty
    }

    private var todayFilter: DeviceActivityFilter {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let end = cal.date(byAdding: .day, value: 1, to: start) ?? Date()
        return DeviceActivityFilter(
            segment: .daily(during: DateInterval(start: start, end: end)),
            users: .all,
            devices: .init(Set<DeviceActivityData.Device.Model>([.iPhone, .iPad])),
            applications: blockManager.selection.applicationTokens,
            categories: blockManager.selection.categoryTokens,
            webDomains: blockManager.selection.webDomainTokens
        )
    }

}
