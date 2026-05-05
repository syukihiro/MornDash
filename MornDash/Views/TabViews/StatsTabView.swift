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

    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        StatsStreakHeroView(streak: viewModel.streakStore.currentStreak)
                        StatsCardsRowView(
                            longestStreak: viewModel.streakStore.longestStreak,
                            totalCompleted: viewModel.streakStore.totalCompleted
                        )
                        blockedDurationSection
                        if subscriptionManager.isPro {
                            comparisonReportSection
                        } else {
                            comparisonReportLockedBanner
                        }
                        emergencyUnlockSection
                        if subscriptionManager.isPro {
                            emergencyComparisonReportSection
                        } else {
                            emergencyComparisonLockedBanner
                        }
                        blockedUsageSection
                        StatsWeekStripView(days: viewModel.streakStore.recentDays(7))
                        StatsContributionGraphView(weeks: viewModel.streakStore.contributionGrid(weeks: 52))
                        StatsBadgesSectionView(longestStreak: viewModel.streakStore.longestStreak)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
            }
            .navigationTitle(Text("tab_stats"))
            .toolbarColorScheme(.dark, for: .navigationBar)
            .paywallSheet(isPresented: $showPaywall)
        }
    }

    // MARK: - Blocked duration (per-day averages)

    private var blockedDurationSection: some View {
        let thisWeek = viewModel.streakStore.averageBlockedSeconds(.currentWeek)
        let pastYear = viewModel.streakStore.averageBlockedSeconds(.pastYear)

        return VStack(alignment: .leading, spacing: 12) {
            StatsSectionHeader(icon: "hourglass", tint: .indigo.opacity(0.85), titleKey: "stats_blocked_duration")

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(StatsFormatters.duration(thisWeek))
                    .font(.system(size: 40, weight: .thin, design: .rounded))
                    .foregroundColor(.white)
                Text("stats_blocked_duration_per_day_suffix")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                Spacer()
                Text("stats_blocked_duration_this_week")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(1)
                    .foregroundColor(.white.opacity(0.45))
            }

            HStack(spacing: 16) {
                blockedDurationMetric(seconds: pastYear, labelKey: "stats_blocked_duration_past_year")
                Spacer()
            }

            if thisWeek == 0 && pastYear == 0 {
                Text("stats_blocked_duration_none")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.top, 2)
            }
        }
        .statsSectionCard(borderColor: .indigo.opacity(0.12))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func blockedDurationMetric(seconds: TimeInterval, labelKey: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(StatsFormatters.duration(seconds))
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
                Text("stats_blocked_duration_per_day_suffix")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.45))
            }
            Text(LocalizedStringKey(labelKey))
                .font(.system(size: 10, weight: .medium))
                .tracking(1)
                .foregroundColor(.white.opacity(0.45))
        }
    }

    // MARK: - Comparison report (Pro)

    private var comparisonReportSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            StatsSectionHeader(icon: "chart.bar.xaxis", tint: .indigo.opacity(0.85), titleKey: "stats_blocked_compare")

            comparisonRow(
                current: viewModel.streakStore.averageBlockedSeconds(.currentWeek),
                previous: viewModel.streakStore.averageBlockedSeconds(.lastWeek),
                labelKey: "stats_blocked_compare_week"
            )
            Divider().background(Color.white.opacity(0.06))
            comparisonRow(
                current: viewModel.streakStore.averageBlockedSeconds(.currentMonth),
                previous: viewModel.streakStore.averageBlockedSeconds(.lastMonth),
                labelKey: "stats_blocked_compare_month"
            )
            Divider().background(Color.white.opacity(0.06))
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
                    .foregroundColor(.white.opacity(0.9))
                Text("stats_blocked_duration_per_day_suffix")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.45))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(LocalizedStringKey(labelKey))
                    .font(.system(size: 10, weight: .medium))
                    .tracking(1)
                    .foregroundColor(.white.opacity(0.45))
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
                .foregroundColor(.white.opacity(0.35))
        }
    }

    private var comparisonReportLockedBanner: some View {
        StatsProLockBanner(
            sectionTitleKey: "stats_blocked_compare",
            titleKey: "stats_blocked_compare_lock_title",
            messageKey: "stats_blocked_compare_lock_message",
            buttonTitleKey: "stats_blocked_compare_unlock_button",
            action: { showPaywall = true }
        )
    }

    // MARK: - Emergency unlocks

    private var emergencyUnlockSection: some View {
        let store = viewModel.emergencyUnlockStore
        let thisWeek = store.count(.currentWeek)
        let thisMonth = store.count(.currentMonth)
        let pastYear = store.count(.pastYear)
        let total = store.count(.total)

        return VStack(alignment: .leading, spacing: 12) {
            StatsSectionHeader(icon: "exclamationmark.triangle.fill", tint: .orange.opacity(0.85), titleKey: "stats_emergency_unlocks")

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(thisWeek)")
                    .font(.system(size: 40, weight: .thin, design: .rounded))
                    .foregroundColor(.white)
                Text("stats_emergency_unlocks_count_unit")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                Spacer()
                Text("stats_emergency_unlocks_this_week")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(1)
                    .foregroundColor(.white.opacity(0.45))
            }

            HStack(spacing: 16) {
                emergencyUnlockMetric(value: thisMonth, labelKey: "stats_emergency_unlocks_this_month")
                Divider()
                    .frame(height: 28)
                    .background(Color.white.opacity(0.08))
                emergencyUnlockMetric(value: pastYear, labelKey: "stats_emergency_unlocks_past_year")
                Divider()
                    .frame(height: 28)
                    .background(Color.white.opacity(0.08))
                emergencyUnlockMetric(value: total, labelKey: "stats_emergency_unlocks_total")
                Spacer()
            }

            if let last = store.lastUnlockDate {
                Text(String(format: NSLocalizedString("stats_emergency_unlocks_last", comment: ""), StatsFormatters.relativeDate(last)))
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.top, 2)
            } else {
                Text("stats_emergency_unlocks_none")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.top, 2)
            }
        }
        .statsSectionCard(borderColor: .orange.opacity(0.12))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func emergencyUnlockMetric(value: Int, labelKey: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text("\(value)")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
                Text("stats_emergency_unlocks_count_unit")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.45))
            }
            Text(LocalizedStringKey(labelKey))
                .font(.system(size: 10, weight: .medium))
                .tracking(1)
                .foregroundColor(.white.opacity(0.45))
        }
    }

    // MARK: - Emergency unlocks comparison report (Pro)

    private var emergencyComparisonReportSection: some View {
        let store = viewModel.emergencyUnlockStore
        return VStack(alignment: .leading, spacing: 14) {
            StatsSectionHeader(icon: "chart.bar.xaxis", tint: .orange.opacity(0.85), titleKey: "stats_emergency_compare")

            emergencyComparisonRow(
                current: store.count(.currentWeek),
                previous: store.count(.lastWeek),
                labelKey: "stats_emergency_compare_week"
            )
            Divider().background(Color.white.opacity(0.06))
            emergencyComparisonRow(
                current: store.count(.currentMonth),
                previous: store.count(.lastMonth),
                labelKey: "stats_emergency_compare_month"
            )
            Divider().background(Color.white.opacity(0.06))
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
                    .foregroundColor(.white.opacity(0.9))
                Text("stats_emergency_unlocks_count_unit")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.45))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(LocalizedStringKey(labelKey))
                    .font(.system(size: 10, weight: .medium))
                    .tracking(1)
                    .foregroundColor(.white.opacity(0.45))
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
                .foregroundColor(.white.opacity(0.35))
        }
    }

    private var emergencyComparisonLockedBanner: some View {
        StatsProLockBanner(
            sectionTitleKey: "stats_emergency_compare",
            titleKey: "stats_emergency_compare_lock_title",
            messageKey: "stats_emergency_compare_lock_message",
            buttonTitleKey: "stats_blocked_compare_unlock_button",
            action: { showPaywall = true }
        )
    }

    // MARK: - Blocked apps usage

    private var blockedUsageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("stats_blocked_usage_today")
                .font(.system(size: 11, weight: .medium))
                .tracking(2)
                .foregroundColor(.white.opacity(0.5))

            if selectionIsEmpty {
                Text("stats_blocked_usage_no_selection")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.4))
                    .frame(maxWidth: .infinity, minHeight: 60)
            } else {
                #if targetEnvironment(simulator)
                Text(verbatim: "DeviceActivityReport unavailable on simulator")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.3))
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
