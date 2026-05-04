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
                        streakHero
                        statCardsRow
                        blockedDurationSection
                        if subscriptionManager.isPro {
                            comparisonReportSection
                        } else {
                            comparisonReportLockedBanner
                        }
                        emergencyUnlockSection
                        blockedUsageSection
                        weekStrip
                        if subscriptionManager.isPro {
                            contributionGraph
                        } else {
                            contributionGraphLockedBanner
                        }
                        badgesSection
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

    private var contributionGraphLockedBanner: some View {
        Button(action: { showPaywall = true }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.orange.opacity(0.85))
                    Text("stats_contributions")
                        .font(.system(size: 11, weight: .medium))
                        .tracking(2)
                        .foregroundColor(.white.opacity(0.5))
                }

                Text("gate_history_lock_title")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)

                Text("gate_history_lock_message")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .semibold))
                    Text("gate_history_unlock_button")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Capsule().fill(Color.orange))
                .padding(.top, 4)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.orange.opacity(0.18), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Hero

    private var streakHero: some View {
        let streak = viewModel.streakStore.currentStreak
        return VStack(spacing: 10) {
            Image(systemName: streak > 0 ? "flame.fill" : "flame")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: streak > 0 ? [.orange, .red] : [.white.opacity(0.25), .white.opacity(0.15)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Text("\(streak)")
                .font(.system(size: 72, weight: .thin, design: .rounded))
                .foregroundColor(.white)

            Text("stats_current_streak")
                .font(.system(size: 12, weight: .medium))
                .tracking(3)
                .foregroundColor(.white.opacity(0.5))

            if streak == 0 {
                Text("stats_no_data")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.4))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
        )
    }

    // MARK: - Stat cards

    private var statCardsRow: some View {
        HStack(spacing: 12) {
            statCard(
                value: "\(viewModel.streakStore.longestStreak)",
                labelKey: "stats_longest_streak",
                icon: "crown.fill",
                tint: .yellow
            )
            statCard(
                value: "\(viewModel.streakStore.totalCompleted)",
                labelKey: "stats_total_completed",
                icon: "checkmark.seal.fill",
                tint: .green
            )
        }
    }

    private func statCard(value: String, labelKey: String, icon: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(tint)
            Text(value)
                .font(.system(size: 32, weight: .thin, design: .rounded))
                .foregroundColor(.white)
            Text(LocalizedStringKey(labelKey))
                .font(.system(size: 11, weight: .medium))
                .tracking(2)
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }

    // MARK: - Blocked duration (per-day averages)

    private var blockedDurationSection: some View {
        let thisWeek = viewModel.streakStore.averageBlockedSeconds(.currentWeek)
        let pastYear = viewModel.streakStore.averageBlockedSeconds(.pastYear)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "hourglass")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.indigo.opacity(0.85))
                Text("stats_blocked_duration")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(2)
                    .foregroundColor(.white.opacity(0.5))
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(formatDuration(thisWeek))
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
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.indigo.opacity(0.12), lineWidth: 1)
                )
        )
    }

    private func blockedDurationMetric(seconds: TimeInterval, labelKey: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(formatDuration(seconds))
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

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let totalMinutes = Int(seconds) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 && minutes > 0 {
            return String(format: NSLocalizedString("onboarding_usage_hm_format", comment: ""), hours, minutes)
        } else if hours > 0 {
            return String(format: NSLocalizedString("onboarding_usage_h_only_format", comment: ""), hours)
        } else if minutes > 0 {
            return String(format: NSLocalizedString("onboarding_usage_m_only_format", comment: ""), minutes)
        } else {
            return NSLocalizedString("onboarding_usage_under_one_m", comment: "")
        }
    }

    // MARK: - Comparison report (Pro)

    private var comparisonReportSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.indigo.opacity(0.85))
                Text("stats_blocked_compare")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(2)
                    .foregroundColor(.white.opacity(0.5))
            }

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
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }

    private func comparisonRow(current: TimeInterval, previous: TimeInterval, labelKey: String) -> some View {
        let delta = percentChange(current: current, previous: previous)
        return HStack(alignment: .firstTextBaseline, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(formatDuration(current))
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

    private func percentChange(current: TimeInterval, previous: TimeInterval) -> Double? {
        guard previous > 0 else { return nil }
        return (current - previous) / previous
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
        Button(action: { showPaywall = true }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.orange.opacity(0.85))
                    Text("stats_blocked_compare")
                        .font(.system(size: 11, weight: .medium))
                        .tracking(2)
                        .foregroundColor(.white.opacity(0.5))
                }

                Text("stats_blocked_compare_lock_title")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)

                Text("stats_blocked_compare_lock_message")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .semibold))
                    Text("stats_blocked_compare_unlock_button")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Capsule().fill(Color.orange))
                .padding(.top, 4)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.orange.opacity(0.18), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Emergency unlocks

    private var emergencyUnlockSection: some View {
        let total = viewModel.emergencyUnlockStore.totalCount
        let thisMonth = viewModel.emergencyUnlockStore.thisMonthCount
        let thisWeek = viewModel.emergencyUnlockStore.thisWeekCount

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.orange.opacity(0.85))
                Text("stats_emergency_unlocks")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(2)
                    .foregroundColor(.white.opacity(0.5))
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(total)")
                    .font(.system(size: 40, weight: .thin, design: .rounded))
                    .foregroundColor(.white)
                Text("stats_emergency_unlocks_total_unit")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }

            HStack(spacing: 16) {
                emergencyUnlockMetric(value: thisWeek, labelKey: "stats_emergency_unlocks_this_week")
                Divider()
                    .frame(height: 28)
                    .background(Color.white.opacity(0.08))
                emergencyUnlockMetric(value: thisMonth, labelKey: "stats_emergency_unlocks_this_month")
                Spacer()
            }

            if let last = viewModel.emergencyUnlockStore.lastUnlockDate {
                Text(String(format: NSLocalizedString("stats_emergency_unlocks_last", comment: ""), relativeDateLabel(last)))
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
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.orange.opacity(0.12), lineWidth: 1)
                )
        )
    }

    private func emergencyUnlockMetric(value: Int, labelKey: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(value)")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.85))
            Text(LocalizedStringKey(labelKey))
                .font(.system(size: 10, weight: .medium))
                .tracking(1)
                .foregroundColor(.white.opacity(0.45))
        }
    }

    private func relativeDateLabel(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale.current
        return formatter.localizedString(for: date, relativeTo: Date())
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
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
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

    // MARK: - Week strip

    private var weekStrip: some View {
        let days = viewModel.streakStore.recentDays(7)
        return VStack(alignment: .leading, spacing: 12) {
            Text("stats_last_7_days")
                .font(.system(size: 11, weight: .medium))
                .tracking(2)
                .foregroundColor(.white.opacity(0.5))

            HStack(spacing: 8) {
                ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                    VStack(spacing: 8) {
                        Text(weekdayLabel(day.date))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                        Circle()
                            .fill(day.completed ? Color.orange : Color.white.opacity(0.08))
                            .frame(width: 28, height: 28)
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                                    .opacity(day.completed ? 1 : 0)
                            )
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }

    private func weekdayLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale.current
        f.setLocalizedDateFormatFromTemplate("EEEEE")
        return f.string(from: date)
    }

    // MARK: - Contribution graph (GitHub-style)

    private var contributionGraph: some View {
        let weeksCount = 52
        let weeks = viewModel.streakStore.contributionGrid(weeks: weeksCount)
        let cellSize: CGFloat = 11
        let cellSpacing: CGFloat = 3
        let columnPitch = cellSize + cellSpacing
        let monthHeaderHeight: CGFloat = 12

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("stats_contributions")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(2)
                    .foregroundColor(.white.opacity(0.5))
                Spacer()
                if let firstDate = weeks.first?.first?.date,
                   let lastDate = weeks.last?.last(where: { !$0.isFuture })?.date {
                    Text(yearRangeLabel(from: firstDate, to: lastDate))
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.35))
                }
            }

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: cellSpacing) {
                        ZStack(alignment: .topLeading) {
                            Color.clear.frame(height: monthHeaderHeight)
                            ForEach(weeks.indices, id: \.self) { i in
                                if let label = monthLabel(forWeek: i, weeks: weeks) {
                                    Text(label)
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundColor(.white.opacity(0.4))
                                        .fixedSize()
                                        .offset(x: CGFloat(i) * columnPitch)
                                }
                            }
                        }
                        .frame(
                            width: max(0, CGFloat(weeks.count) * columnPitch - cellSpacing),
                            height: monthHeaderHeight,
                            alignment: .topLeading
                        )

                        HStack(spacing: cellSpacing) {
                            ForEach(Array(weeks.enumerated()), id: \.offset) { idx, week in
                                VStack(spacing: cellSpacing) {
                                    ForEach(Array(week.enumerated()), id: \.offset) { _, cell in
                                        contributionCell(cell)
                                            .frame(width: cellSize, height: cellSize)
                                    }
                                }
                                .id(idx)
                            }
                        }
                    }
                    .padding(.trailing, 4)
                }
                .onAppear {
                    DispatchQueue.main.async {
                        proxy.scrollTo(weeks.count - 1, anchor: .trailing)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }

    private func contributionCell(_ cell: StreakStore.ContributionDay) -> some View {
        let fill: Color
        if cell.isFuture {
            fill = Color.white.opacity(0.03)
        } else if cell.completed {
            fill = Color.orange
        } else {
            fill = Color.white.opacity(0.08)
        }
        return RoundedRectangle(cornerRadius: 2)
            .fill(fill)
    }

    private func monthLabel(forWeek index: Int, weeks: [[StreakStore.ContributionDay]]) -> String? {
        guard let firstDay = weeks[index].first else { return nil }
        let cal = Calendar.current
        if index == 0 {
            return shortMonthLabel(firstDay.date)
        }
        guard let prevFirst = weeks[index - 1].first else { return nil }
        let prevMonth = cal.component(.month, from: prevFirst.date)
        let currentMonth = cal.component(.month, from: firstDay.date)
        return prevMonth != currentMonth ? shortMonthLabel(firstDay.date) : nil
    }

    private func shortMonthLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale.current
        f.setLocalizedDateFormatFromTemplate("MMM")
        return f.string(from: date)
    }

    private func yearRangeLabel(from start: Date, to end: Date) -> String {
        let cal = Calendar.current
        let startYear = cal.component(.year, from: start)
        let endYear = cal.component(.year, from: end)
        return startYear == endYear ? "\(endYear)" : "\(startYear) – \(endYear)"
    }

    // MARK: - Badges

    private var badgesSection: some View {
        let longest = viewModel.streakStore.longestStreak
        return VStack(alignment: .leading, spacing: 12) {
            Text("stats_badges")
                .font(.system(size: 11, weight: .medium))
                .tracking(2)
                .foregroundColor(.white.opacity(0.5))

            HStack(spacing: 10) {
                ForEach(Badge.all) { badge in
                    badgeView(
                        unlocked: longest >= badge.threshold,
                        labelKey: badge.labelKey,
                        icon: badge.icon,
                        color: badge.color
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }

    private func badgeView(unlocked: Bool, labelKey: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .regular))
                .foregroundColor(unlocked ? color : .white.opacity(0.15))
                .frame(width: 48, height: 48)
                .background(
                    Circle().fill(unlocked ? color.opacity(0.15) : Color.white.opacity(0.04))
                )
            Text(LocalizedStringKey(labelKey))
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(unlocked ? .white.opacity(0.8) : .white.opacity(0.3))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}
