import SwiftUI

struct StatsStreakHeroView: View {
    let streak: Int

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: streak > 0 ? "flame.fill" : "flame")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: streak > 0 ? [.orange, .red] : [.white.opacity(0.25), .white.opacity(0.15)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(streak)")
                    .font(.system(size: 72, weight: .thin, design: .rounded))
                Text(StatsFormatters.streakDayUnit(count: streak))
                    .font(.system(size: 28, weight: .light, design: .rounded))
                    .foregroundColor(.white.opacity(0.65))
            }
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
}

struct StatsCardsRowView: View {
    let longestStreak: Int
    let totalCompleted: Int

    var body: some View {
        HStack(spacing: 12) {
            statCard(value: "\(longestStreak)", labelKey: "stats_longest_streak", icon: "crown.fill", tint: .yellow, showsDayUnit: true)
            statCard(value: "\(totalCompleted)", labelKey: "stats_total_completed", icon: "checkmark.seal.fill", tint: .green, showsDayUnit: true)
        }
    }

    private func statCard(value: String, labelKey: String, icon: String, tint: Color, showsDayUnit: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(tint)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 32, weight: .thin, design: .rounded))
                if showsDayUnit, let count = Int(value) {
                    Text(StatsFormatters.streakDayUnit(count: count))
                        .font(.system(size: 16, weight: .light, design: .rounded))
                        .foregroundColor(.white.opacity(0.55))
                }
            }
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

                ForEach(Array(days.enumerated()), id: \.offset) { _, day in
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

struct StatsWeekStripView: View {
    let days: [(date: Date, completed: Bool)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("stats_last_7_days")
                .font(.system(size: 11, weight: .medium))
                .tracking(2)
                .foregroundColor(.white.opacity(0.5))

            HStack(spacing: 8) {
                ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                    VStack(spacing: 8) {
                        Text(StatsFormatters.weekday(day.date))
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
        .statsSectionCard()
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
                .onAppear {
                    DispatchQueue.main.async {
                        proxy.scrollTo(weeks.count - 1, anchor: .trailing)
                    }
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
