import SwiftUI
import FamilyControls

struct BlockingView: View {
    @ObservedObject var viewModel: HomeViewModel
    @ObservedObject var blockManager: BlockManager

    @State private var showGiveUpConfirm = false
    @State private var activeWorkoutTaskID: UUID?

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(.indigo)

                Text("blocking_header")
                    .font(.system(size: 14, weight: .medium))
                    .tracking(4)
                    .foregroundColor(.indigo)

                Text("blocking_subtitle")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .padding(.top, 20)

            HStack(spacing: 4) {
                Text("\(viewModel.taskStore.completedCount)")
                    .font(.system(size: 48, weight: .thin, design: .rounded))
                    .foregroundColor(.white)
                Text("/ \(viewModel.taskStore.tasks.count)")
                    .font(.system(size: 24, weight: .thin, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
            }

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(sortedTasks, id: \.task.id) { item in
                        TaskTicketCardView(
                            task: item.task,
                            index: item.index,
                            onPunch: {
                                guard !item.task.isCompletedToday else { return }
                                if item.task.isWorkoutTask {
                                    activeWorkoutTaskID = item.task.id
                                    return
                                }
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    viewModel.toggleTask(item.task.id, blockManager: blockManager)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .layoutPriority(1)

            Button(action: { showGiveUpConfirm = true }) {
                Text("blocking_give_up")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
                    .underline()
            }
            .padding(.bottom, 30)
        }
        .fullScreenCover(isPresented: $showGiveUpConfirm) {
            EmergencyUnlockView(viewModel: viewModel, blockManager: blockManager)
        }
        .fullScreenCover(item: workoutTaskBinding) { task in
            WorkoutSessionView(
                task: task,
                onComplete: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.toggleTask(task.id, blockManager: blockManager)
                    }
                },
                onCancel: {}
            )
        }
    }

    private var workoutTaskBinding: Binding<TaskItem?> {
        Binding(
            get: {
                guard let id = activeWorkoutTaskID else { return nil }
                return viewModel.taskStore.tasks.first { $0.id == id }
            },
            set: { newValue in
                activeWorkoutTaskID = newValue?.id
            }
        )
    }

    private var sortedTasks: [(index: Int, task: TaskItem)] {
        viewModel.taskStore.tasks.enumerated()
            .map { (index: $0.offset, task: $0.element) }
            .sorted { lhs, rhs in
                if lhs.task.isCompletedToday == rhs.task.isCompletedToday {
                    return lhs.index < rhs.index
                }
                return !lhs.task.isCompletedToday
            }
    }
}
