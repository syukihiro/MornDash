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
    let badge: Badge?
    let onDismiss: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accentTheme) private var accentTheme

    init(
        streak: Int,
        style: RoutineCelebrationStyle,
        badge: Badge? = nil,
        onDismiss: @escaping () -> Void
    ) {
        self.streak = streak
        self.style = style
        self.badge = badge
        self.onDismiss = onDismiss
    }

    @State private var phase: AnimationPhase = .initial
    @State private var ringPulse = false
    @State private var sunRotation: Double = 0
    @State private var sparkleSeed: Int = 0
    @State private var compactVisible = false
    @State private var compactDidDismiss = false

    private let accentGreen = Color(red: 0.45, green: 0.95, blue: 0.65)
    private let accentYellow = Color.yellow
    private let accentGold = Color(red: 1.0, green: 0.88, blue: 0.55)

    private var celebrationPrimary: Color {
        colorScheme == .dark ? (badge?.color ?? accentGreen) : accentTheme.idleColor
    }

    private var celebrationSecondary: Color {
        colorScheme == .dark ? Color(red: 0.75, green: 1, blue: 0.8) : accentYellow
    }

    private var celebrationIconGradient: [Color] {
        if let badge {
            if colorScheme == .dark {
                return [MornDashColors.iconGradientLeading(colorScheme), badge.color, accentYellow]
            }
            return [
                Color(red: 0.45, green: 0.20, blue: 0.03),
                accentTheme.idleColor,
                badge.color.opacity(0.95),
                accentGold,
            ]
        }
        if colorScheme == .dark {
            return [MornDashColors.iconGradientLeading(colorScheme), accentGreen, accentYellow]
        }
        return [
            Color(red: 0.45, green: 0.20, blue: 0.03),
            accentTheme.idleColor,
            Color(red: 1.0, green: 0.74, blue: 0.18),
        ]
    }

    private var sparkleColors: [Color] {
        if let badge {
            if colorScheme == .dark {
                return [badge.color, accentYellow, celebrationPrimary, MornDashColors.iconGradientLeading(colorScheme)]
            }
            return [accentTheme.idleColor, accentGold, badge.color, accentTheme.idleColor.opacity(0.75)]
        }
        return [celebrationPrimary, accentYellow, accentTheme.idleColor, MornDashColors.iconGradientLeading(colorScheme)]
    }

    private var heroIconName: String {
        badge?.icon ?? "checkmark.seal.fill"
    }

    private var eyebrowKey: LocalizedStringKey {
        badge == nil ? "routine_celebration_eyebrow" : "badge_celebration_eyebrow"
    }

    private var titleKey: LocalizedStringKey {
        if let badge {
            return LocalizedStringKey(badge.labelKey)
        }
        return "routine_celebration_title"
    }

    private var showsStreakPill: Bool {
        streak > 0
    }

    private var eyebrowStyle: AnyShapeStyle {
        if let badge {
            AnyShapeStyle(
                LinearGradient(
                    colors: [celebrationPrimary, badge.color.opacity(0.9)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        } else {
            AnyShapeStyle(
                LinearGradient(
                    colors: [
                        celebrationPrimary.opacity(colorScheme == .dark ? 0.95 : 0.9),
                        accentTheme.idleColor.opacity(colorScheme == .dark ? 0.75 : 0.85),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        }
    }

    private var sparkleCount: Int {
        badge == nil ? 28 : 30
    }

    private var lightTitleSize: CGFloat {
        badge == nil ? 34 : 32
    }

    private var celebrationButtonGradient: [Color] {
        colorScheme == .dark
            ? [accentGreen, celebrationSecondary]
            : accentTheme.idleGradientColors
    }

    private var backdropPrimaryGlowOpacity: Double {
        colorScheme == .dark ? 0.45 : 0.34
    }

    private var backdropSecondaryGlowOpacity: Double {
        colorScheme == .dark ? 0.2 : 0.28
    }

    private var heroRingStrokeOpacity: Double {
        colorScheme == .dark ? 0.3 : 0.38
    }

    private var heroBlurLeadingOpacity: Double {
        colorScheme == .dark ? 0.4 : 0.55
    }

    private var heroInnerFillOpacity: Double {
        colorScheme == .dark ? 0.12 : 0.16
    }

    private var heroIconShadowOpacity: Double {
        colorScheme == .dark ? 0.65 : 0.55
    }

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
            if sparkleCount > 0 {
                CelebrationSparkleField(
                    seed: sparkleSeed,
                    colors: sparkleColors,
                    active: phase != .initial,
                    count: sparkleCount
                )
            }
            fullContent
        }
    }

    private var fullBackdrop: some View {
        ZStack {
            MornDashColors.celebrationBackdrop(colorScheme).ignoresSafeArea()

            RadialGradient(
                colors: [celebrationPrimary.opacity(phase == .initial ? 0.0 : backdropPrimaryGlowOpacity), .clear],
                center: .center,
                startRadius: 0,
                endRadius: phase == .initial ? 60 : 480
            )
            .ignoresSafeArea()
            .animation(.easeOut(duration: 1.6), value: phase)

            RadialGradient(
                colors: [accentTheme.idleColor.opacity(phase == .initial ? 0.0 : backdropSecondaryGlowOpacity), .clear],
                center: UnitPoint(x: 0.5, y: 0.35),
                startRadius: 40,
                endRadius: 500
            )
            .ignoresSafeArea()
            .animation(.easeOut(duration: 2.0), value: phase)

            if let badge {
                RadialGradient(
                    colors: [badge.color.opacity(phase == .initial ? 0.0 : (colorScheme == .dark ? 0.18 : 0.14)), .clear],
                    center: UnitPoint(x: 0.5, y: 0.42),
                    startRadius: 80,
                    endRadius: 420
                )
                .ignoresSafeArea()
                .animation(.easeOut(duration: 2.2), value: phase)
            }
        }
    }

    private var fullContent: some View {
        VStack(spacing: colorScheme == .light ? 32 : 28) {
            Spacer()

            Text(eyebrowKey)
                .font(.system(size: 11, weight: .semibold))
                .tracking(6)
                .foregroundStyle(eyebrowStyle)
                .opacity(phase == .initial ? 0 : 1)
                .animation(.easeOut(duration: 0.6).delay(0.45), value: phase)

            celebrationHero
                .scaleEffect(phase == .initial ? 0.15 : 1.0)
                .opacity(phase == .initial ? 0 : 1)
                .animation(.spring(response: 0.72, dampingFraction: 0.52).delay(0.12), value: phase)

            VStack(spacing: colorScheme == .light ? 12 : 14) {
                Text(titleKey)
                    .font(.system(size: colorScheme == .light ? lightTitleSize : (badge == nil ? 30 : 32), weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(MornDashColors.labelPrimary(colorScheme))

                Text("routine_celebration_message")
                    .font(.system(size: colorScheme == .light ? 16 : 15, weight: colorScheme == .light ? .regular : .medium))
                    .multilineTextAlignment(.center)
                    .lineSpacing(colorScheme == .light ? 6 : 4)
                    .foregroundColor(MornDashColors.labelSecondary(colorScheme))

                if showsStreakPill {
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
                    .tracking(colorScheme == .light ? 0.5 : 1)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: celebrationButtonGradient,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(
                                color: celebrationPrimary.opacity(colorScheme == .dark ? 0.55 : 0.38),
                                radius: colorScheme == .dark ? 18 : 14,
                                y: colorScheme == .dark ? 8 : 6
                            )
                    )
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 28)
            .opacity(phase == .settled ? 1 : 0)
            .offset(y: phase == .settled ? 0 : 20)
            .animation(.easeOut(duration: 0.5).delay(0.95), value: phase)
        }
    }

    private var celebrationHero: some View {
        ZStack {
            Circle()
                .stroke(celebrationPrimary.opacity(heroRingStrokeOpacity), lineWidth: 1.5)
                .frame(width: 220, height: 220)
                .scaleEffect(ringPulse ? 1.12 : 1.0)
                .opacity(ringPulse ? 0.0 : 0.9)
                .animation(.easeOut(duration: 1.6).repeatForever(autoreverses: false), value: ringPulse)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            accentTheme.idleColor.opacity(heroBlurLeadingOpacity),
                            celebrationPrimary.opacity(colorScheme == .dark ? 0.08 : 0.12),
                        ],
                        center: .center,
                        startRadius: 4,
                        endRadius: 110
                    )
                )
                .frame(width: 200, height: 200)
                .blur(radius: 20)

            Circle()
                .fill(celebrationPrimary.opacity(heroInnerFillOpacity))
                .frame(width: 160, height: 160)
                .overlay(
                    Circle().strokeBorder(
                        LinearGradient(
                            colors: [
                                celebrationPrimary.opacity(colorScheme == .dark ? 0.6 : 0.75),
                                accentTheme.idleColor.opacity(colorScheme == .dark ? 0.35 : 0.5),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
                )

            heroIcon
                .rotationEffect(.degrees(sunRotation))
        }
    }

    @ViewBuilder
    private var heroIcon: some View {
        Image(systemName: heroIconName)
            .font(.system(size: 72, weight: .regular))
            .foregroundStyle(
                LinearGradient(
                    colors: celebrationIconGradient,
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .shadow(color: celebrationPrimary.opacity(heroIconShadowOpacity), radius: 20)
            .symbolEffect(.bounce, value: phase == .burst)
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
                        .foregroundStyle(celebrationPrimary)
                        .symbolEffect(.bounce, value: compactVisible)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("routine_celebration_compact_title")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(MornDashColors.labelPrimary(colorScheme))

                        if streak > 0 {
                            HStack(spacing: 5) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(MornDashColors.streakFlame)
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
                                .strokeBorder(celebrationPrimary.opacity(colorScheme == .dark ? 0.25 : 0.4), lineWidth: 1)
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
                .font(.system(size: 14))
                .foregroundStyle(MornDashColors.streakFlame)
            Text(String(format: NSLocalizedString("streak_days_format", comment: ""), streak))
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(MornDashColors.labelPrimary(colorScheme, opacity: colorScheme == .dark ? 0.88 : 0.92))
        }
        .padding(.top, 2)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background {
            Capsule()
                .fill(
                    colorScheme == .dark
                        ? MornDashColors.fieldBackground(colorScheme)
                        : celebrationPrimary.opacity(0.12)
                )
                .overlay(
                    Capsule().strokeBorder(
                        celebrationPrimary.opacity(colorScheme == .dark ? 0.22 : 0.45),
                        lineWidth: 1
                    )
                )
                .shadow(color: celebrationPrimary.opacity(colorScheme == .dark ? 0.15 : 0.28), radius: 12, y: 2)
        }
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
