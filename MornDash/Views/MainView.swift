import SwiftUI
import FamilyControls

struct MainView: View {
    @ObservedObject var viewModel: HomeViewModel
    @ObservedObject var blockManager: BlockManager
    let colorForState: Color
    let showGlow: Bool
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accentTheme) private var accentTheme

    private var allTasksCompletedToday: Bool {
        !viewModel.taskStore.tasks.isEmpty && viewModel.taskStore.allCompletedToday
    }

    var body: some View {
        if allTasksCompletedToday {
            CompletedHomeView(viewModel: viewModel)
        } else {
            waitingHome
        }
    }

    private var waitingHome: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 30) {
                if viewModel.streakStore.currentStreak > 0 {
                    streakPill
                        .padding(.top, 20)
                }

                VStack(spacing: 12) {
                    Image(systemName: "sunrise.fill")
                        .font(.system(size: 70, weight: .ultraLight))
                        .foregroundStyle(
                            LinearGradient(
                                colors: accentTheme.idleGradientColors,
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .shadow(color: colorForState.opacity(0.6), radius: showGlow ? 30 : 10)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: showGlow)

                    Text("main_next_block")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(MornDashColors.secondaryText(colorScheme, opacity: 0.6))
                        .tracking(2)

                    Text(startTimeString)
                        .font(.system(size: 64, weight: .thin, design: .rounded))
                        .foregroundColor(MornDashColors.primaryText(colorScheme))
                }
                .padding(.top, viewModel.streakStore.currentStreak > 0 ? 0 : 40)

                if viewModel.taskStore.tasks.isEmpty {
                    Text("main_no_tasks")
                        .font(.system(size: 14))
                        .foregroundColor(MornDashColors.secondaryText(colorScheme, opacity: 0.5))
                        .padding()
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("main_todays_tasks")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(MornDashColors.secondaryText(colorScheme, opacity: 0.5))
                            .tracking(2)

                        ForEach(sortedTasks) { task in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: task.isCompletedToday ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(
                                        task.isCompletedToday
                                            ? accentTheme.completedAccentColor
                                            : MornDashColors.secondaryText(colorScheme, opacity: 0.3)
                                    )
                                    .padding(.top, 2)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(task.title)
                                        .foregroundColor(MornDashColors.primaryText(colorScheme, opacity: 0.8))
                                        .strikethrough(task.isCompletedToday, color: MornDashColors.secondaryText(colorScheme, opacity: 0.4))
                                    if task.hasTimer, let seconds = task.timerDurationSeconds {
                                        HStack(spacing: 3) {
                                            Image(systemName: "timer")
                                            Text(TaskTimerFormatters.durationLabel(seconds: seconds))
                                        }
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(accentTheme.blockingColor.opacity(0.9))
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .font(.system(size: 16))
                        }
                    }
                    .padding()
                    .frame(maxWidth: 320, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(MornDashColors.cardFill(colorScheme))
                    )
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 40)
        }
    }

    private var startTimeString: String {
        String(format: "%02d:%02d", viewModel.config.startHour, viewModel.config.startMinute)
    }

    private var sortedTasks: [TaskItem] {
        viewModel.taskStore.tasks.enumerated()
            .sorted { lhs, rhs in
                if lhs.element.isCompletedToday == rhs.element.isCompletedToday {
                    return lhs.offset < rhs.offset
                }
                return !lhs.element.isCompletedToday
            }
            .map(\.element)
    }

    private var streakPill: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .foregroundStyle(accentTheme.streakFlameGradientStyle)
            Text(String(format: NSLocalizedString("streak_days_format", comment: ""), viewModel.streakStore.currentStreak))
                .foregroundColor(MornDashColors.primaryText(colorScheme, opacity: 0.9))
        }
        .font(.system(size: 13, weight: .semibold))
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(
            Capsule().fill(MornDashColors.cardFill(colorScheme))
        )
        .overlay(
            Capsule().strokeBorder(accentTheme.idleColor.opacity(0.25), lineWidth: 1)
        )
    }
}
