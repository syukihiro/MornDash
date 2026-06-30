import SwiftUI

/// タスク別アナリティクス（無料）— 期間トグル + タスク別達成日数 + 直近 7 日ドット
struct StatsTaskBreakdownSection: View {
    let history: TaskHistoryStore
    let tasks: [TaskItem]
    @Binding var period: TaskHistoryStore.Period

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                StatsSectionHeader(icon: "chart.bar.doc.horizontal.fill", tint: .indigo.opacity(0.85), titleKey: "stats_task_breakdown")
                Spacer()
                periodToggle
            }

            if perTaskRows.isEmpty {
                Text(period == .currentMonth ? "stats_task_no_data_month" : "stats_task_no_data_year")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.top, 4)
            } else {
                VStack(spacing: 14) {
                    ForEach(perTaskRows, id: \.id) { row in
                        taskRow(row)
                    }
                }
            }
        }
        .statsSectionCard(borderColor: .indigo.opacity(0.12))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var periodToggle: some View {
        HStack(spacing: 0) {
            toggleButton(.currentMonth, key: "stats_task_period_month")
            toggleButton(.currentYear, key: "stats_task_period_year")
        }
        .background(Capsule().fill(Color.white.opacity(0.06)))
    }

    private func toggleButton(_ value: TaskHistoryStore.Period, key: String) -> some View {
        let selected = period == value
        return Button {
            withAnimation(.easeInOut(duration: 0.18)) { period = value }
        } label: {
            Text(LocalizedStringKey(key))
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(selected ? .black : .white.opacity(0.6))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(selected ? Color.white.opacity(0.85) : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }

    private struct TaskRow: Identifiable {
        let id: UUID
        let title: String
        let count: Int
        let total: Int
        let recent7: [(date: Date, completed: Bool)]
    }

    private var perTaskRows: [TaskRow] {
        let total = history.calendarDayCount(in: period)
        return tasks.compactMap { task in
            let count = history.count(taskId: task.id, in: period)
            guard count > 0 else { return nil }
            return TaskRow(
                id: task.id,
                title: task.title,
                count: count,
                total: total,
                recent7: history.recentSevenDays(taskId: task.id)
            )
        }
    }

    private func taskRow(_ row: TaskRow) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(row.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(1)
                Text(String(format: NSLocalizedString("stats_task_consistency_format", comment: ""), row.count, row.total))
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.45))
            }
            Spacer(minLength: 8)
            HStack(spacing: 4) {
                ForEach(Array(row.recent7.enumerated()), id: \.offset) { _, day in
                    Circle()
                        .fill(day.completed ? Color.indigo.opacity(0.85) : Color.white.opacity(0.1))
                        .frame(width: 8, height: 8)
                }
            }
        }
    }
}

/// タスク別の前期間比（Pro）
struct StatsTaskComparisonSection: View {
    let history: TaskHistoryStore
    let tasks: [TaskItem]
    let period: TaskHistoryStore.Period

    var body: some View {
        let rows = comparisonRows
        if rows.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    StatsSectionHeader(icon: "chart.bar.xaxis", tint: .indigo.opacity(0.85), titleKey: "stats_task_compare")
                    Spacer()
                    Text(LocalizedStringKey(period == .currentMonth ? "stats_blocked_compare_month" : "stats_blocked_compare_year"))
                        .font(.system(size: 10, weight: .medium))
                        .tracking(1)
                        .foregroundColor(.white.opacity(0.45))
                }

                ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                    if index > 0 {
                        Divider().background(Color.white.opacity(0.06))
                    }
                    comparisonTaskRow(row)
                }
            }
            .statsSectionCard()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private struct ComparisonRow: Identifiable {
        let id: UUID
        let title: String
        let current: Int
        let delta: Double?
    }

    private var previousPeriod: TaskHistoryStore.Period {
        period == .currentMonth ? .lastMonth : .lastYear
    }

    private var comparisonRows: [ComparisonRow] {
        tasks.compactMap { task in
            let current = history.count(taskId: task.id, in: period)
            let previous = history.count(taskId: task.id, in: previousPeriod)
            guard current > 0 || previous > 0 else { return nil }
            return ComparisonRow(
                id: task.id,
                title: task.title,
                current: current,
                delta: StatsFormatters.percentChange(current: Double(current), previous: Double(previous))
            )
        }
    }

    private func comparisonTaskRow(_ row: ComparisonRow) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(row.title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(1)
            Spacer(minLength: 8)
            Text("\(row.current)")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.85))
            deltaLabel(row.delta)
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
}
