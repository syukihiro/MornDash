import SwiftUI

struct StatsStreakSummaryView: View {
    let streak: Int
    let longestStreak: Int
    let totalCompleted: Int
    let recentDays: [(date: Date, completed: Bool)]
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accentTheme) private var accentTheme

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
                    .foregroundColor(MornDashColors.labelTertiary(colorScheme))
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
                .fill(MornDashColors.cardFill(colorScheme))
                .overlay {
                    if colorScheme == .light {
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(MornDashColors.hairline(colorScheme), lineWidth: 1)
                    }
                }
        )
        .mornDashCardShadow(colorScheme)
    }

    private var hero: some View {
        VStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Image(systemName: streak > 0 ? "flame.fill" : "flame")
                    .font(.system(size: 24, weight: .light))
                    .foregroundStyle(
                        streak > 0
                            ? AnyShapeStyle(accentTheme.streakFlameGradientStyle)
                            : AnyShapeStyle(
                                LinearGradient(
                                    colors: MornDashColors.flameInactiveGradient(colorScheme),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
                    .offset(y: -1)

                Text("\(streak)")
                    .font(.system(size: 44, weight: .thin, design: .rounded))

                Text(StatsFormatters.streakDayUnit(count: streak))
                    .font(.system(size: 18, weight: .light, design: .rounded))
                    .foregroundColor(MornDashColors.labelSecondary(colorScheme))
            }
            .foregroundColor(MornDashColors.labelPrimary(colorScheme))

            Text("stats_current_streak")
                .font(.system(size: 10, weight: .medium))
                .tracking(2)
                .foregroundColor(MornDashColors.labelTertiary(colorScheme))
        }
    }

    private var weekSection: some View {
        VStack(spacing: 10) {
            HStack {
                Text("stats_last_7_days")
                    .font(.system(size: 10, weight: .medium))
                    .tracking(1.5)
                    .foregroundColor(MornDashColors.labelTertiary(colorScheme))
                Spacer()
                Text(String(format: NSLocalizedString("stats_week_progress_short", comment: ""), weekCompleted))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(MornDashColors.labelSecondary(colorScheme))
            }

            HStack(spacing: 0) {
                ForEach(Array(recentDays.enumerated()), id: \.offset) { _, day in
                    Image(systemName: day.completed ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(day.completed ? accentTheme.idleColor : MornDashColors.calendarEmptyDay(colorScheme))
                        .frame(maxWidth: .infinity)
                }
            }

            GeometryReader { proxy in
                let progress = CGFloat(weekCompleted) / 7.0
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(MornDashColors.progressTrack(colorScheme))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [accentTheme.idleColor.opacity(0.85), accentTheme.idleColor],
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
                        .foregroundColor(MornDashColors.labelTertiary(colorScheme))
                }

                Text(
                    String(
                        format: NSLocalizedString("stats_next_milestone_days", comment: ""),
                        badgeShortName(nextBadge),
                        daysLeft
                    )
                )
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(MornDashColors.labelPrimary(colorScheme, opacity: 0.85))

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(MornDashColors.progressTrack(colorScheme))
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
                    .foregroundColor(MornDashColors.labelSecondary(colorScheme))
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
        .foregroundColor(MornDashColors.labelMuted(colorScheme))
        .frame(maxWidth: .infinity)
    }

    private func badgeShortName(_ badge: Badge) -> String {
        NSLocalizedString(badge.labelKey, comment: "")
            .replacingOccurrences(of: "\n", with: "")
    }
}

struct StatsMonthCalendarView: View {
    let days: [StreakStore.MonthCalendarDay]
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accentTheme) private var accentTheme

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
                    .foregroundColor(MornDashColors.labelTertiary(colorScheme))
                Spacer()
                Text(monthTitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(MornDashColors.labelMuted(colorScheme))
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 8) {
                ForEach(Array(weekdayHeaders.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(MornDashColors.labelMuted(colorScheme))
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
                    .fill(accentTheme.idleColor)
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
            } else {
                Circle()
                    .fill(MornDashColors.calendarCellFill(colorScheme, inMonth: day.isInMonth, isFuture: day.isFuture))
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
                Circle().strokeBorder(accentTheme.idleColor.opacity(0.7), lineWidth: 1.5)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: size)
    }

    private func dayTextColor(_ day: StreakStore.MonthCalendarDay) -> Color {
        if day.isFuture { return MornDashColors.labelMuted(colorScheme) }
        if day.isToday { return accentTheme.idleColor.opacity(0.9) }
        return MornDashColors.labelSecondary(colorScheme)
    }
}

struct StatsBadgesSectionView: View {
    let longestStreak: Int
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("stats_badges")
                .font(.system(size: 11, weight: .medium))
                .tracking(2)
                .foregroundColor(MornDashColors.labelTertiary(colorScheme))

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
                .foregroundColor(unlocked ? color : MornDashColors.calendarEmptyDay(colorScheme))
                .frame(width: 48, height: 48)
                .background(
                    Circle().fill(unlocked ? color.opacity(0.15) : MornDashColors.badgeLockedFill(colorScheme))
                )
            Text(LocalizedStringKey(labelKey))
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(unlocked ? MornDashColors.labelPrimary(colorScheme, opacity: 0.85) : MornDashColors.labelMuted(colorScheme))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct StatsContributionGraphView: View {
    let weeks: [[StreakStore.ContributionDay]]
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accentTheme) private var accentTheme

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
                    .foregroundColor(MornDashColors.labelTertiary(colorScheme))
                Spacer()
                if let firstDate = weeks.first?.first?.date,
                   let lastDate = weeks.last?.last(where: { !$0.isFuture })?.date {
                    Text(StatsFormatters.yearRange(from: firstDate, to: lastDate))
                        .font(.system(size: 10))
                        .foregroundColor(MornDashColors.labelMuted(colorScheme))
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
                                        .foregroundColor(MornDashColors.labelTertiary(colorScheme))
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
            fill = MornDashColors.contributionEmpty(colorScheme)
        } else if cell.completed {
            fill = accentTheme.idleColor
        } else {
            fill = MornDashColors.contributionLow(colorScheme, accent: accentTheme)
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
