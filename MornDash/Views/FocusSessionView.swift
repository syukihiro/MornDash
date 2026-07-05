import SwiftUI

struct FocusSessionView: View {
    let task: TaskItem
    let onComplete: () -> Void
    let onCancel: () -> Void
    let onTick: (Int) -> Void

    @StateObject private var detector: FocusDetectionViewModel
    @AppStorage("focus_hint_seen") private var hintSeen: Bool = false
    @State private var showHint: Bool = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accentTheme) private var accentTheme

    init(task: TaskItem, onComplete: @escaping () -> Void, onCancel: @escaping () -> Void, onTick: @escaping (Int) -> Void) {
        self.task = task
        self.onComplete = onComplete
        self.onCancel = onCancel
        self.onTick = onTick
        _detector = StateObject(wrappedValue: FocusDetectionViewModel(
            kind: task.focusKind ?? .study,
            targetSeconds: task.focusTargetSeconds ?? 1800,
            initialAccumulated: task.focusAccumulatedSeconds ?? 0
        ))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            #if targetEnvironment(simulator)
            simulatorFallback
            #else
            if detector.cameraManager.permissionDenied {
                CameraPermissionDeniedView()
            } else {
                cameraLayer
            }
            #endif

            VStack {
                topBar
                Spacer()
                if showsCountdownOverlay {
                    countdownOverlay
                } else {
                    timerDisplay
                }
                Spacer()
                statusFooter
            }
            .padding()
        }
        .keepScreenAwakeWhileVisible()
        .onAppear {
            detector.onTick = onTick
            detector.onTargetReached = handleTargetReached
            detector.start()
            if !hintSeen {
                showHint = true
            }
        }
        .onDisappear {
            detector.stop()
        }
        .sheet(isPresented: $showHint) {
            hintSheet
        }
    }

    private var cameraLayer: some View {
        ZStack {
            CameraPreview(cameraManager: detector.cameraManager)
                .ignoresSafeArea()

            FaceGuideOverlay(
                boundingBox: detector.faceBoundingBox,
                showsGuide: showsFaceGuide,
                strokeColor: guideStrokeColor
            )
            .ignoresSafeArea()

            scrim
        }
    }

    private var showsFaceGuide: Bool {
        switch detector.sessionPhase {
        case .searching, .aligning, .calibrating:
            true
        default:
            false
        }
    }

    private var guideStrokeColor: Color {
        switch detector.sessionPhase {
        case .active, .go:
            detector.isDetected ? accentTheme.completedAccentColor : .yellow
        case .calibrating:
            accentTheme.blockingColor
        default:
            .white.opacity(0.85)
        }
    }

    private var showsCountdownOverlay: Bool {
        switch detector.sessionPhase {
        case .countdown, .go:
            true
        default:
            false
        }
    }

    private var scrim: some View {
        LinearGradient(
            colors: [Color.black.opacity(0.72), .clear, .clear, Color.black.opacity(0.72)],
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
                .lineLimit(1)
            Spacer()
            Color.clear.frame(width: 36, height: 36)
        }
    }

    private var countdownOverlay: some View {
        ZStack {
            switch detector.sessionPhase {
            case .countdown(let value):
                Text("\(value)")
                    .font(.system(size: 120, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: accentTheme.idleGradientColors,
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: accentTheme.idleColor.opacity(0.45), radius: 24)
                    .transition(.scale.combined(with: .opacity))
            case .go:
                Text("workout_countdown_go")
                    .font(.system(size: 72, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: accentTheme.idleGradientColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: accentTheme.idleColor.opacity(0.5), radius: 20)
                    .transition(.scale.combined(with: .opacity))
            default:
                EmptyView()
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.72), value: detector.sessionPhase)
    }

    private var timerDisplay: some View {
        let remaining = max(0, detector.targetSeconds - detector.elapsedSeconds)
        let minutes = remaining / 60
        let seconds = remaining % 60

        return VStack(spacing: 10) {
            if case .calibrating(let progress) = detector.sessionPhase {
                calibrationBanner(progress: progress)
            }

            Text("focus_session_remaining")
                .font(.system(size: 12, weight: .medium))
                .tracking(3)
                .foregroundColor(.white.opacity(0.5))

            Text(String(format: "%02d:%02d", minutes, seconds))
                .font(.system(size: 80, weight: .thin, design: .rounded))
                .monospacedDigit()
                .foregroundColor(.white)
                .contentTransition(.numericText())

            if detector.sessionPhase == .active {
                activeStatusBadge
                    .padding(.top, 8)
            }

            ProgressView(value: sessionProgress)
                .progressViewStyle(.linear)
                .tint(accentTheme.blockingColor)
                .frame(maxWidth: 220)
                .padding(.top, 8)
        }
    }

    private var activeStatusBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(detector.isDetected ? accentTheme.completedAccentColor : Color.yellow)
                .frame(width: 8, height: 8)
            Text(detector.feedbackMessage)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(detector.isDetected ? accentTheme.completedAccentColor : .yellow)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill((detector.isDetected ? accentTheme.completedAccentColor : Color.yellow).opacity(0.12))
        )
    }

    private func calibrationBanner(progress: Double) -> some View {
        VStack(spacing: 8) {
            Text("focus_status_hold_still")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))

            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .tint(accentTheme.idleColor)
                .frame(maxWidth: 180)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.45))
                .overlay(
                    Capsule().strokeBorder(accentTheme.idleColor.opacity(0.35), lineWidth: 1)
                )
        )
    }

    private var statusFooter: some View {
        VStack(spacing: 8) {
            if detector.sessionPhase != .active {
                Text(detector.feedbackMessage)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
            }

            Text("focus_privacy_notice")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 20)
    }

    private var sessionProgress: Double {
        guard detector.targetSeconds > 0 else { return 0 }
        return min(1.0, Double(detector.elapsedSeconds) / Double(detector.targetSeconds))
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
        }
    }

    private var hintSheet: some View {
        VStack(spacing: 20) {
            Text("focus_hint_setup_title")
                .font(.headline)
                .foregroundColor(.white)

            Text("focus_hint_setup_body")
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            Button(action: {
                hintSeen = true
                showHint = false
            }) {
                Text("focus_hint_setup_close")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(Color.white))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 30)
        .background(Color.black.ignoresSafeArea())
        .presentationDetents([.medium])
    }

    private func handleTargetReached() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            onComplete()
            dismiss()
        }
    }

    private func handleCancel() {
        detector.stop()
        onCancel()
        dismiss()
    }
}
