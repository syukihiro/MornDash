import SwiftUI
import FamilyControls
import UIKit

struct BlockingView: View {
    @ObservedObject var viewModel: HomeViewModel
    @ObservedObject var blockManager: BlockManager

    @State private var showGiveUpConfirm = false
    @State private var activeWorkoutTaskID: UUID?
    @State private var activeTimerTaskID: UUID?
    @State private var activeFocusTaskID: UUID?

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
                                if item.task.isFocusTask {
                                    activeFocusTaskID = item.task.id
                                    return
                                }
                                if item.task.isWorkoutTask {
                                    activeWorkoutTaskID = item.task.id
                                    return
                                }
                                if item.task.hasTimer {
                                    activeTimerTaskID = item.task.id
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
        .fullScreenCover(item: timerTaskBinding) { task in
            TimerSessionView(
                task: task,
                onComplete: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.toggleTask(task.id, blockManager: blockManager)
                    }
                },
                onCancel: {}
            )
        }
        .fullScreenCover(item: focusTaskBinding) { task in
            FocusSessionView(
                task: task,
                onComplete: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.toggleTask(task.id, blockManager: blockManager)
                    }
                    viewModel.taskStore.clearFocusSession(task.id)
                },
                onCancel: {
                    viewModel.taskStore.clearFocusSession(task.id)
                },
                onTick: { accumulated in
                    viewModel.taskStore.updateFocusAccumulated(task.id, accumulated: accumulated, sessionStart: Date())
                    viewModel.taskStore.save()
                }
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

    private var timerTaskBinding: Binding<TaskItem?> {
        Binding(
            get: {
                guard let id = activeTimerTaskID else { return nil }
                return viewModel.taskStore.tasks.first { $0.id == id }
            },
            set: { newValue in
                activeTimerTaskID = newValue?.id
            }
        )
    }

    private var focusTaskBinding: Binding<TaskItem?> {
        Binding(
            get: {
                guard let id = activeFocusTaskID else { return nil }
                return viewModel.taskStore.tasks.first { $0.id == id }
            },
            set: { newValue in
                activeFocusTaskID = newValue?.id
            }
        )
    }
}

struct TimerSessionView: View {
    let task: TaskItem
    let onComplete: () -> Void
    let onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss
    private let totalSeconds: Int
    @State private var remainingSeconds: Int
    @State private var isRunning: Bool = false
    @State private var tickTimer: Timer?

    init(task: TaskItem, onComplete: @escaping () -> Void, onCancel: @escaping () -> Void) {
        let duration = max(task.timerDurationSeconds ?? 0, 1)
        self.task = task
        self.onComplete = onComplete
        self.onCancel = onCancel
        self.totalSeconds = duration
        _remainingSeconds = State(initialValue: duration)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 20) {
                Text("timer_session_title")
                    .font(.system(size: 13, weight: .medium))
                    .tracking(3)
                    .foregroundColor(.indigo)

                Text(task.title)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding(.horizontal, 28)

                Text(timeText)
                    .font(.system(size: 58, weight: .medium, design: .rounded))
                    .fontWidth(.expanded)
                    .monospacedDigit()
                    .foregroundColor(.white)
                    .contentTransition(.numericText())

                HourglassTimerView(
                    progress: progress,
                    isRunning: isRunning,
                    isFinished: remainingSeconds == 0
                )
                .frame(height: 250)
                .padding(.top, 4)

                HStack(spacing: 12) {
                    Button(action: cancel) {
                        Text("common_cancel")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Capsule().fill(Color.white.opacity(0.12)))
                    }
                    .buttonStyle(.plain)

                    Button(action: toggleRunning) {
                        Image(systemName: isRunning ? "pause.fill" : "play.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Capsule().fill(Color.white))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 6)
            }
            .padding(22)
        }
        .onAppear {
            setIdleTimer(disabled: false)
        }
        .onDisappear {
            stopTicking()
            setIdleTimer(disabled: false)
        }
        .onChange(of: isRunning) { _, running in
            setIdleTimer(disabled: running)
            if running {
                startTicking()
            } else {
                stopTicking()
            }
        }
    }

    private var timeText: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return max(0, min(1, Double(remainingSeconds) / Double(totalSeconds)))
    }

    private func toggleRunning() {
        isRunning.toggle()
    }

    private func startTicking() {
        stopTicking()
        tickTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            guard remainingSeconds > 0 else { return }
            remainingSeconds -= 1
            if remainingSeconds <= 0 {
                finish()
            }
        }
    }

    private func stopTicking() {
        tickTimer?.invalidate()
        tickTimer = nil
    }

    private func finish() {
        isRunning = false
        stopTicking()
        onComplete()
        dismiss()
    }

    private func cancel() {
        isRunning = false
        stopTicking()
        onCancel()
        dismiss()
    }

    private func setIdleTimer(disabled: Bool) {
        UIApplication.shared.isIdleTimerDisabled = disabled
    }
}

private struct HourglassTimerView: View {
    let progress: Double
    let isRunning: Bool
    let isFinished: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            Canvas { canvas, size in
                let now = context.date.timeIntervalSinceReferenceDate
                let w = min(size.width, 180)
                let h = min(size.height, 230)
                let origin = CGPoint(x: (size.width - w) / 2, y: (size.height - h) / 2)

                let topY = origin.y + 14
                let bottomY = origin.y + h - 14
                let midY = origin.y + h / 2
                let centerX = origin.x + w / 2
                let topHalfWidth = w * 0.36
                let neckHalfWidth = w * 0.024

                func halfWidth(at y: CGFloat) -> CGFloat {
                    if y <= midY {
                        let t = (y - topY) / max(midY - topY, 1)
                        return topHalfWidth * (1 - t) + neckHalfWidth * t
                    } else {
                        let t = (y - midY) / max(bottomY - midY, 1)
                        return neckHalfWidth * (1 - t) + topHalfWidth * t
                    }
                }

                let topFill = max(0, min(1, progress))
                let bottomFill = 1 - topFill
                let topSandTopY = topY + (1 - topFill) * (midY - topY)
                let bottomSandTopY = midY + (1 - bottomFill) * (bottomY - midY)

                let accent = isFinished ? Color.red.opacity(0.9) : Color.orange.opacity(0.9)

                if isFinished {
                    let pulse = (sin(now * 4) + 1) / 2
                    let radius = w * (0.50 + 0.08 * pulse)
                    var ring = Path()
                    ring.addEllipse(in: CGRect(
                        x: centerX - radius,
                        y: midY - radius,
                        width: radius * 2,
                        height: radius * 2
                    ))
                    canvas.stroke(
                        ring,
                        with: .color(.red.opacity(0.25 + 0.25 * pulse)),
                        lineWidth: 1
                    )
                }

                // Hourglass frame
                var topGlass = Path()
                topGlass.move(to: CGPoint(x: centerX - topHalfWidth, y: topY))
                topGlass.addLine(to: CGPoint(x: centerX + topHalfWidth, y: topY))
                topGlass.addQuadCurve(
                    to: CGPoint(x: centerX + neckHalfWidth, y: midY),
                    control: CGPoint(x: centerX + topHalfWidth + 8, y: topY + 8)
                )
                topGlass.addLine(to: CGPoint(x: centerX - neckHalfWidth, y: midY))
                topGlass.addQuadCurve(
                    to: CGPoint(x: centerX - topHalfWidth, y: topY),
                    control: CGPoint(x: centerX - topHalfWidth - 8, y: topY + 8)
                )
                topGlass.closeSubpath()

                var bottomGlass = Path()
                bottomGlass.move(to: CGPoint(x: centerX - neckHalfWidth, y: midY))
                bottomGlass.addLine(to: CGPoint(x: centerX + neckHalfWidth, y: midY))
                bottomGlass.addQuadCurve(
                    to: CGPoint(x: centerX + topHalfWidth, y: bottomY),
                    control: CGPoint(x: centerX + topHalfWidth + 8, y: bottomY - 8)
                )
                bottomGlass.addLine(to: CGPoint(x: centerX - topHalfWidth, y: bottomY))
                bottomGlass.addQuadCurve(
                    to: CGPoint(x: centerX - neckHalfWidth, y: midY),
                    control: CGPoint(x: centerX - topHalfWidth - 8, y: bottomY - 8)
                )
                bottomGlass.closeSubpath()

                canvas.fill(topGlass, with: .color(Color(red: 0.12, green: 0.10, blue: 0.08, opacity: 0.95)))
                canvas.fill(bottomGlass, with: .color(Color(red: 0.12, green: 0.10, blue: 0.08, opacity: 0.95)))

                // Top sand
                if topFill > 0.001 {
                    var topSand = Path()
                    let y = topSandTopY
                    let hw = halfWidth(at: y)
                    topSand.move(to: CGPoint(x: centerX - hw, y: y))
                    topSand.addLine(to: CGPoint(x: centerX + hw, y: y))
                    topSand.addLine(to: CGPoint(x: centerX + neckHalfWidth, y: midY))
                    topSand.addLine(to: CGPoint(x: centerX - neckHalfWidth, y: midY))
                    topSand.closeSubpath()
                    canvas.fill(topSand, with: .linearGradient(
                        Gradient(colors: [
                            Color(red: 0.98, green: 0.80, blue: 0.45, opacity: 0.95),
                            Color(red: 0.88, green: 0.58, blue: 0.30, opacity: 0.90)
                        ]),
                        startPoint: CGPoint(x: centerX, y: y),
                        endPoint: CGPoint(x: centerX, y: midY)
                    ))
                }

                // Bottom sand
                if bottomFill > 0.001 {
                    var bottomSand = Path()
                    let y = bottomSandTopY
                    let hw = halfWidth(at: y)
                    bottomSand.move(to: CGPoint(x: centerX - hw, y: y))
                    bottomSand.addLine(to: CGPoint(x: centerX + hw, y: y))
                    bottomSand.addLine(to: CGPoint(x: centerX + topHalfWidth, y: bottomY))
                    bottomSand.addLine(to: CGPoint(x: centerX - topHalfWidth, y: bottomY))
                    bottomSand.closeSubpath()
                    canvas.fill(bottomSand, with: .linearGradient(
                        Gradient(colors: [
                            Color(red: 0.90, green: 0.60, blue: 0.34, opacity: 0.88),
                            Color(red: 0.99, green: 0.82, blue: 0.48, opacity: 0.95)
                        ]),
                        startPoint: CGPoint(x: centerX, y: y),
                        endPoint: CGPoint(x: centerX, y: bottomY)
                    ))
                }

                // Falling stream and particles while running.
                if isRunning && !isFinished {
                    var stream = Path()
                    stream.move(to: CGPoint(x: centerX, y: midY))
                    stream.addLine(to: CGPoint(x: centerX, y: bottomSandTopY - 2))
                    canvas.stroke(stream, with: .color(.orange.opacity(0.85)), lineWidth: 2)

                    for i in 0..<14 {
                        let phase = now * 120 + Double(i * 31)
                        let px = centerX + CGFloat(sin(phase * 0.03) * 3.0)
                        let travel = CGFloat((phase.truncatingRemainder(dividingBy: 100)) / 100.0)
                        let py = (midY + 1) + (bottomSandTopY - midY) * travel
                        let dotRect = CGRect(x: px - 1.2, y: py - 1.2, width: 2.4, height: 2.4)
                        canvas.fill(Path(ellipseIn: dotRect), with: .color(.orange.opacity(0.85)))
                    }
                }

                canvas.stroke(topGlass, with: .color(accent.opacity(0.55)), lineWidth: 1.5)
                canvas.stroke(bottomGlass, with: .color(accent.opacity(0.55)), lineWidth: 1.5)

                var topCap = Path()
                topCap.move(to: CGPoint(x: centerX - topHalfWidth - 6, y: topY - 6))
                topCap.addLine(to: CGPoint(x: centerX + topHalfWidth + 6, y: topY - 6))
                canvas.stroke(topCap, with: .color(accent.opacity(0.7)), style: StrokeStyle(lineWidth: 3, lineCap: .round))

                var bottomCap = Path()
                bottomCap.move(to: CGPoint(x: centerX - topHalfWidth - 6, y: bottomY + 6))
                bottomCap.addLine(to: CGPoint(x: centerX + topHalfWidth + 6, y: bottomY + 6))
                canvas.stroke(bottomCap, with: .color(accent.opacity(0.7)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
            }
        }
        .drawingGroup()
    }
}
