import SwiftUI

enum RoutineCelebrationStyle {
    case full
    case compact

    /// 初回完了、またはバッジ閾値の連続日数に到達した日はフル演出。
    static func forCompletion(streak: Int, isFirstCompletionEver: Bool) -> RoutineCelebrationStyle {
        if isFirstCompletionEver || Badge.thresholds.contains(streak) {
            return .full
        }
        return .compact
    }
}

struct RoutineCompleteCelebrationView: View {
    let streak: Int
    let style: RoutineCelebrationStyle
    let onDismiss: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    @State private var phase: AnimationPhase = .initial
    @State private var ringPulse = false
    @State private var sunRotation: Double = 0
    @State private var sparkleSeed: Int = 0
    @State private var compactVisible = false
    @State private var compactDidDismiss = false

    private let accentGreen = Color(red: 0.45, green: 0.95, blue: 0.65)
    private let accentOrange = Color.orange
    private let accentYellow = Color.yellow

    private enum AnimationPhase {
        case initial
        case burst
        case settled
    }

    var body: some View {
        Group {
            switch style {
            case .full:
                fullCelebration
            case .compact:
                compactCelebration
            }
        }
        .onAppear {
            switch style {
            case .full:
                runFullIntro()
            case .compact:
                runCompactIntro()
            }
        }
    }

    // MARK: - Full

    private var fullCelebration: some View {
        ZStack {
            fullBackdrop
            CelebrationSparkleField(
                seed: sparkleSeed,
                colors: [accentGreen, accentYellow, accentOrange, MornDashColors.iconGradientLeading(colorScheme)],
                active: phase != .initial,
                count: 28
            )
            fullContent
        }
    }

    private var fullBackdrop: some View {
        ZStack {
            MornDashColors.celebrationBackdrop(colorScheme).ignoresSafeArea()

            RadialGradient(
                colors: [accentGreen.opacity(phase == .initial ? 0.0 : (colorScheme == .dark ? 0.45 : 0.32)), .clear],
                center: .center,
                startRadius: 0,
                endRadius: phase == .initial ? 60 : 480
            )
            .ignoresSafeArea()
            .animation(.easeOut(duration: 1.6), value: phase)

            RadialGradient(
                colors: [accentOrange.opacity(phase == .initial ? 0.0 : (colorScheme == .dark ? 0.2 : 0.16)), .clear],
                center: UnitPoint(x: 0.5, y: 0.35),
                startRadius: 40,
                endRadius: 500
            )
            .ignoresSafeArea()
            .animation(.easeOut(duration: 2.0), value: phase)
        }
    }

    private var fullContent: some View {
        VStack(spacing: 28) {
            Spacer()

            Text("routine_celebration_eyebrow")
                .font(.system(size: 11, weight: .semibold))
                .tracking(6)
                .foregroundColor(accentGreen.opacity(0.95))
                .opacity(phase == .initial ? 0 : 1)
                .animation(.easeOut(duration: 0.6).delay(0.45), value: phase)

            ZStack {
                Circle()
                    .stroke(accentGreen.opacity(0.3), lineWidth: 1.5)
                    .frame(width: 220, height: 220)
                    .scaleEffect(ringPulse ? 1.12 : 1.0)
                    .opacity(ringPulse ? 0.0 : 0.9)
                    .animation(.easeOut(duration: 1.6).repeatForever(autoreverses: false), value: ringPulse)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [accentOrange.opacity(0.4), accentGreen.opacity(0.08)],
                            center: .center,
                            startRadius: 4,
                            endRadius: 110
                        )
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: 20)

                Circle()
                    .fill(accentGreen.opacity(0.12))
                    .frame(width: 160, height: 160)
                    .overlay(
                        Circle().strokeBorder(
                            LinearGradient(
                                colors: [accentGreen.opacity(0.6), accentOrange.opacity(0.35)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                    )

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 72, weight: .regular))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [MornDashColors.iconGradientLeading(colorScheme), accentGreen, accentYellow],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: accentGreen.opacity(0.65), radius: 20)
                    .rotationEffect(.degrees(sunRotation))
            }
            .scaleEffect(phase == .initial ? 0.15 : 1.0)
            .opacity(phase == .initial ? 0 : 1)
            .animation(.spring(response: 0.72, dampingFraction: 0.52).delay(0.12), value: phase)

            VStack(spacing: 10) {
                Text("routine_celebration_title")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(MornDashColors.labelPrimary(colorScheme))

                Text("routine_celebration_message")
                    .font(.system(size: 15, weight: .medium))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .foregroundColor(MornDashColors.labelSecondary(colorScheme))

                if streak > 0 {
                    streakPill
                }
            }
            .padding(.horizontal, 36)
            .opacity(phase == .initial ? 0 : 1)
            .offset(y: phase == .initial ? 16 : 0)
            .animation(.easeOut(duration: 0.6).delay(0.55), value: phase)

            Spacer()

            Button(action: onDismiss) {
                Text("routine_celebration_continue")
                    .font(.system(size: 15, weight: .semibold))
                    .tracking(1)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [accentGreen, Color(red: 0.75, green: 1, blue: 0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: accentGreen.opacity(0.55), radius: 18, y: 8)
                    )
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 28)
            .opacity(phase == .settled ? 1 : 0)
            .offset(y: phase == .settled ? 0 : 20)
            .animation(.easeOut(duration: 0.5).delay(0.95), value: phase)
        }
    }

    // MARK: - Compact

    private var compactCelebration: some View {
        ZStack {
            MornDashColors.modalScrim(colorScheme)
                .ignoresSafeArea()
                .opacity(compactVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.25), value: compactVisible)
                .onTapGesture { dismissCompact() }

            VStack {
                Spacer()

                HStack(spacing: 14) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(accentGreen)
                        .symbolEffect(.bounce, value: compactVisible)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("routine_celebration_compact_title")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(MornDashColors.labelPrimary(colorScheme))

                        if streak > 0 {
                            HStack(spacing: 5) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.orange)
                                Text(String(format: NSLocalizedString("streak_days_format", comment: ""), streak))
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(MornDashColors.labelSecondary(colorScheme))
                            }
                        }
                    }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(MornDashColors.compactToastBackground(colorScheme))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .strokeBorder(accentGreen.opacity(colorScheme == .dark ? 0.25 : 0.35), lineWidth: 1)
                        )
                        .mornDashCardShadow(colorScheme)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 36)
                .offset(y: compactVisible ? 0 : 72)
                .opacity(compactVisible ? 1 : 0)
                .animation(.spring(response: 0.45, dampingFraction: 0.82), value: compactVisible)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { dismissCompact() }
    }

    // MARK: - Shared

    private var streakPill: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .foregroundStyle(
                    LinearGradient(colors: [.orange, .red], startPoint: .top, endPoint: .bottom)
                )
            Text(String(format: NSLocalizedString("streak_days_format", comment: ""), streak))
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(MornDashColors.labelPrimary(colorScheme, opacity: 0.85))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(Capsule().fill(MornDashColors.fieldBackground(colorScheme)))
        .padding(.top, 6)
    }

    // MARK: - Intro

    private func runFullIntro() {
        sparkleSeed = Int.random(in: 0..<10_000)
        withAnimation { phase = .burst }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            ringPulse = true
        }
        withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: false)) {
            sunRotation = 8
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation { phase = .settled }
        }
    }

    private func runCompactIntro() {
        withAnimation { compactVisible = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            dismissCompact()
        }
    }

    private func dismissCompact() {
        guard compactVisible, !compactDidDismiss else { return }
        compactDidDismiss = true
        withAnimation(.easeIn(duration: 0.2)) {
            compactVisible = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            onDismiss()
        }
    }
}
