import SwiftUI

struct WorkoutSessionView: View {
    let task: TaskItem
    let onComplete: () -> Void
    let onCancel: () -> Void

    @StateObject private var counter: WorkoutCounterViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accentTheme) private var accentTheme

    init(task: TaskItem, onComplete: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.task = task
        self.onComplete = onComplete
        self.onCancel = onCancel
        _counter = StateObject(wrappedValue: WorkoutCounterViewModel(targetReps: task.targetReps ?? 20))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            #if targetEnvironment(simulator)
            simulatorFallback
            #else
            CameraPreview(cameraManager: counter.cameraManager)
                .ignoresSafeArea()
                .overlay(scrim)
            #endif

            VStack {
                topBar
                Spacer()
                countDisplay
                Spacer()
                statusFooter
            }
            .padding()
        }
        .onAppear {
            counter.onTargetReached = handleTargetReached
            counter.start()
        }
        .onDisappear {
            counter.stop()
        }
    }

    private var scrim: some View {
        LinearGradient(
            colors: [Color.black.opacity(0.7), .clear, .clear, Color.black.opacity(0.7)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var topBar: some View {
        HStack {
            Button(action: handleCancel) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Circle().fill(Color.white.opacity(0.15)))
            }
            Spacer()
            Text(task.title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            Spacer()
            Color.clear.frame(width: 36, height: 36)
        }
    }

    private var countDisplay: some View {
        VStack(spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(counter.count)")
                    .font(.system(size: 96, weight: .thin, design: .rounded))
                    .foregroundColor(.white)
                    .contentTransition(.numericText())
                Text("/ \(counter.targetReps)")
                    .font(.system(size: 32, weight: .thin, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
            }
            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .tint(accentTheme.blockingColor)
                .frame(maxWidth: 220)
        }
    }

    private var statusFooter: some View {
        Text(counter.feedbackMessage)
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.white.opacity(0.85))
            .padding(.bottom, 20)
    }

    private var simulatorFallback: some View {
        VStack(spacing: 14) {
            Image(systemName: "camera.fill")
                .font(.system(size: 44))
                .foregroundColor(.white.opacity(0.3))
            Text("workout_simulator_notice")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button("workout_simulator_complete") { handleTargetReached() }
                .buttonStyle(.borderedProminent)
                .tint(accentTheme.blockingColor)
        }
    }

    private var progress: Double {
        guard counter.targetReps > 0 else { return 0 }
        return min(1.0, Double(counter.count) / Double(counter.targetReps))
    }

    private func handleTargetReached() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            onComplete()
            dismiss()
        }
    }

    private func handleCancel() {
        counter.stop()
        onCancel()
        dismiss()
    }
}
