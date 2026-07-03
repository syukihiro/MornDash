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

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                Spacer()

                if detector.cameraManager.permissionDenied {
                    CameraPermissionDeniedView()
                        .frame(maxHeight: 280)
                } else {
                    countdownDisplay

                    statusBadge
                        .padding(.top, 16)

                    progressBar
                        .padding(.horizontal, 40)
                        .padding(.top, 20)
                }

                Spacer()

                Text("focus_privacy_notice")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.3))
                    .padding(.bottom, 24)
            }
        }
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

    // MARK: - Subviews

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
            #if targetEnvironment(simulator)
            Color.clear.frame(width: 36, height: 36)
            #else
            CameraPreview(cameraManager: detector.cameraManager)
                .frame(width: 80, height: 107)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                )
            #endif
        }
    }

    private var countdownDisplay: some View {
        let remaining = max(0, detector.targetSeconds - detector.elapsedSeconds)
        let minutes = remaining / 60
        let seconds = remaining % 60
        return VStack(spacing: 6) {
            Text(NSLocalizedString("focus_session_remaining", comment: ""))
                .font(.system(size: 12, weight: .medium))
                .tracking(3)
                .foregroundColor(.white.opacity(0.5))
            Text(String(format: "%02d:%02d", minutes, seconds))
                .font(.system(size: 80, weight: .thin, design: .rounded))
                .monospacedDigit()
                .foregroundColor(.white)
                .contentTransition(.numericText())
        }
    }

    private var statusBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(detector.isDetected ? Color.green : Color.yellow)
                .frame(width: 8, height: 8)
            Text(statusMessage)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(detector.isDetected ? .green : .yellow)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill((detector.isDetected ? Color.green : Color.yellow).opacity(0.12))
        )
    }

    private var statusMessage: String {
        if detector.isDetected {
            return NSLocalizedString("focus_status_detected", comment: "")
        }
        switch detector.statusReason {
        case .ok:
            return NSLocalizedString("focus_status_detected", comment: "")
        case .noFace:
            return NSLocalizedString("focus_status_no_face", comment: "")
        case .multipleFaces:
            return NSLocalizedString("focus_status_multiple_faces", comment: "")
        case .lowQuality:
            return NSLocalizedString("focus_status_low_quality", comment: "")
        case .badAngle:
            return NSLocalizedString("focus_status_bad_angle", comment: "")
        case .faceTooSmall:
            return NSLocalizedString("focus_status_face_too_small", comment: "")
        }
    }

    private var progressBar: some View {
        let progress = detector.targetSeconds > 0
            ? min(1.0, Double(detector.elapsedSeconds) / Double(detector.targetSeconds))
            : 0
        return ProgressView(value: progress)
            .progressViewStyle(.linear)
            .tint(accentTheme.blockingColor)
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

    // MARK: - Actions

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
