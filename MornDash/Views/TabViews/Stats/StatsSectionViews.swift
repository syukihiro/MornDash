import SwiftUI

struct StatsStreakSummaryView: View {
    let streak: Int
    let longestStreak: Int
    let totalCompleted: Int
    let recentDays: [(date: Date, completed: Bool)]

    private var weekCompleted: Int { recentDays.filter(\.completed).count }

    private var nextBadge: Badge? {
        Badge.all.first { longestStreak < $0.threshold }
    }

    var body: some View {
        VStack(spacing: 18) {
            hero

            if streak == 0 && totalCompleted == 0 {
                Text("stats_no_data")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.4))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            } else {
                weekSection
                milestoneSection
                footerStats
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.05))
        )
    }

    private var hero: some View {
        VStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Image(systemName: streak > 0 ? "flame.fill" : "flame")
                    .font(.system(size: 24, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: streak > 0 ? [.orange, .red] : [.white.opacity(0.25), .white.opacity(0.15)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .offset(y: -1)

                Text("\(streak)")
                    .font(.system(size: 44, weight: .thin, design: .rounded))

                Text(StatsFormatters.streakDayUnit(count: streak))
                    .font(.system(size: 18, weight: .light, design: .rounded))
                    .foregroundColor(.white.opacity(0.65))
            }
            .foregroundColor(.white)

            Text("stats_current_streak")
                .font(.system(size: 10, weight: .medium))
                .tracking(2)
                .foregroundColor(.white.opacity(0.45))
        }
    }

    private var weekSection: some View {
        VStack(spacing: 10) {
            HStack {
                Text("stats_last_7_days")
                    .font(.system(size: 10, weight: .medium))
                    .tracking(1.5)
                    .foregroundColor(.white.opacity(0.45))
                Spacer()
                Text(String(format: NSLocalizedString("stats_week_progress_short", comment: ""), weekCompleted))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.55))
            }

            HStack(spacing: 0) {
                ForEach(Array(recentDays.enumerated()), id: \.offset) { _, day in
                    Image(systemName: day.completed ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(day.completed ? Color.orange : Color.white.opacity(0.15))
                        .frame(maxWidth: .infinity)
                }
            }

            GeometryReader { proxy in
                let progress = CGFloat(weekCompleted) / 7.0
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.orange.opacity(0.85), .orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, proxy.size.width * progress))
                }
            }
            .frame(height: 4)
        }
    }

    @ViewBuilder
    private var milestoneSection: some View {
        if let nextBadge {
            let daysLeft = max(nextBadge.threshold - longestStreak, 0)
            let progress = min(Double(longestStreak) / Double(nextBadge.threshold), 1.0)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: nextBadge.icon)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(nextBadge.color)
                    Text("stats_next_milestone")
                        .font(.system(size: 10, weight: .medium))
                        .tracking(1.5)
                        .foregroundColor(.white.opacity(0.45))
                }

                Text(
                    String(
                        format: NSLocalizedString("stats_next_milestone_days", comment: ""),
                        badgeShortName(nextBadge),
                        daysLeft
                    )
                )
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.75))

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                        Capsule()
                            .fill(nextBadge.color.opacity(0.85))
                            .frame(width: max(0, proxy.size.width * progress))
                    }
                }
                .frame(height: 4)
            }
        } else {
            HStack(spacing: 6) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.yellow.opacity(0.8))
                Text("stats_all_badges_unlocked")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.55))
            }
        }
    }

    private var footerStats: some View {
        Text(
            String(
                format: NSLocalizedString("stats_summary_footer", comment: ""),
                longestStreak,
                totalCompleted
            )
        )
        .font(.system(size: 11, weight: .medium))
        .foregroundColor(.white.opacity(0.35))
        .frame(maxWidth: .infinity)
    }

    private func badgeShortName(_ badge: Badge) -> String {
        NSLocalizedString(badge.labelKey, comment: "")
            .replacingOccurrences(of: "\n", with: "")
    }
}

struct StatsMonthCalendarView: View {
    let days: [StreakStore.MonthCalendarDay]

    private var weekdayHeaders: [String] {
        let cal = Calendar.current
        let symbols = cal.shortWeekdaySymbols
        let start = cal.firstWeekday - 1
        return (0..<7).map { symbols[(start + $0) % 7] }
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("yyyyMMMM")
        return formatter.string(from: Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("stats_month_calendar")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(2)
                    .foregroundColor(.white.opacity(0.5))
                Spacer()
                Text(monthTitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 8) {
                ForEach(Array(weekdayHeaders.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.35))
                        .frame(maxWidth: .infinity)
                }

                ForEach(days) { day in
                    monthDayCell(day)
                }
            }
        }
        .statsSectionCard()
    }

    @ViewBuilder
    private func monthDayCell(_ day: StreakStore.MonthCalendarDay) -> some View {
        let size: CGFloat = 32
        ZStack {
            if day.completed && day.isInMonth {
                Circle()
                    .fill(Color.orange)
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
            } else {
                Circle()
                    .fill(day.isInMonth ? Color.white.opacity(day.isFuture ? 0.04 : 0.08) : Color.clear)
                if day.isInMonth {
                    Text("\(day.day)")
                        .font(.system(size: 12, weight: day.isToday ? .semibold : .regular, design: .rounded))
                        .foregroundColor(dayTextColor(day))
                }
            }
        }
        .frame(width: size, height: size)
        .overlay {
            if day.isToday {
                Circle().strokeBorder(Color.orange.opacity(0.7), lineWidth: 1.5)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: size)
    }

    private func dayTextColor(_ day: StreakStore.MonthCalendarDay) -> Color {
        if day.isFuture { return .white.opacity(0.2) }
        if day.isToday { return .orange.opacity(0.9) }
        return .white.opacity(0.55)
    }
}

struct StatsBadgesSectionView: View {
    let longestStreak: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("stats_badges")
                .font(.system(size: 11, weight: .medium))
                .tracking(2)
                .foregroundColor(.white.opacity(0.5))

            HStack(spacing: 10) {
                ForEach(Badge.all) { badge in
                    badgeView(
                        unlocked: longestStreak >= badge.threshold,
                        labelKey: badge.labelKey,
                        icon: badge.icon,
                        color: badge.color
                    )
                }
            }
        }
        .statsSectionCard()
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

struct StatsContributionGraphView: View {
    let weeks: [[StreakStore.ContributionDay]]

    var body: some View {
        let cellSize: CGFloat = 11
        let cellSpacing: CGFloat = 3
        let columnPitch = cellSize + cellSpacing
        let monthHeaderHeight: CGFloat = 12
        let lastWeekIndex = max(weeks.count - 1, 0)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("stats_contributions")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(2)
                    .foregroundColor(.white.opacity(0.5))
                Spacer()
                if let firstDate = weeks.first?.first?.date,
                   let lastDate = weeks.last?.last(where: { !$0.isFuture })?.date {
                    Text(StatsFormatters.yearRange(from: firstDate, to: lastDate))
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
                                if let label = monthLabel(forWeek: i) {
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
                .defaultScrollAnchor(.trailing)
                .task(id: weeks.count) {
                    guard weeks.count > 0 else { return }
                    try? await Task.sleep(for: .milliseconds(80))
                    proxy.scrollTo(lastWeekIndex, anchor: .trailing)
                }
            }
        }
        .statsSectionCard()
        .frame(maxWidth: .infinity, alignment: .leading)
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

    private func monthLabel(forWeek index: Int) -> String? {
        guard let firstDay = weeks[index].first else { return nil }
        let cal = Calendar.current
        if index == 0 {
            return StatsFormatters.shortMonth(firstDay.date)
        }
        guard let prevFirst = weeks[index - 1].first else { return nil }
        let prevMonth = cal.component(.month, from: prevFirst.date)
        let currentMonth = cal.component(.month, from: firstDay.date)
        return prevMonth != currentMonth ? StatsFormatters.shortMonth(firstDay.date) : nil
    }
}
