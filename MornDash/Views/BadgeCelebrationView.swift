import SwiftUI

struct BadgeCelebrationView: View {
    let badge: Badge
    let streak: Int
    let onDismiss: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accentTheme) private var accentTheme

    @State private var phase: AnimationPhase = .initial
    @State private var ringPulse = false
    @State private var glowBreath = false
    @State private var rotation: Double = 0
    @State private var sparkleSeed: Int = 0

    private let accentGold = Color(red: 1.0, green: 0.88, blue: 0.55)

    private enum AnimationPhase {
        case initial
        case burst
        case settled
    }

    private var celebrationGlow: Color {
        colorScheme == .dark ? badge.color : accentTheme.idleColor
    }

    private var sparkleColors: [Color] {
        if colorScheme == .dark {
            return [badge.color, accentGold, .white, celebrationGlow]
        }
        return [accentTheme.idleColor, accentGold, badge.color, accentTheme.idleColor.opacity(0.75)]
    }

    private var iconGradient: [Color] {
        if colorScheme == .dark {
            return [MornDashColors.iconGradientLeading(colorScheme), badge.color, accentGold]
        }
        return [
            Color(red: 0.45, green: 0.20, blue: 0.03),
            accentTheme.idleColor,
            badge.color.opacity(0.95),
            accentGold,
        ]
    }

    private var buttonGradient: [Color] {
        colorScheme == .dark
            ? [badge.color, badge.color.opacity(0.72)]
            : accentTheme.idleGradientColors
    }

    var body: some View {
        ZStack {
            backdrop
            CelebrationSparkleField(
                seed: sparkleSeed,
                colors: sparkleColors,
                active: phase != .initial,
                count: 30
            )
            content
        }
        .onAppear { runIntro() }
    }

    // MARK: - Layers

    private var backdrop: some View {
        ZStack {
            MornDashColors.celebrationBackdrop(colorScheme).ignoresSafeArea()

            RadialGradient(
                colors: [
                    celebrationGlow.opacity(phase == .initial ? 0.0 : (colorScheme == .dark ? 0.5 : 0.28)),
                    .clear,
                ],
                center: .center,
                startRadius: 0,
                endRadius: phase == .initial ? 60 : 500
            )
            .ignoresSafeArea()
            .animation(.easeOut(duration: 1.6), value: phase)

            RadialGradient(
                colors: [
                    badge.color.opacity(phase == .initial ? 0.0 : (colorScheme == .dark ? 0.22 : 0.14)),
                    accentGold.opacity(phase == .initial ? 0.0 : (colorScheme == .dark ? 0.08 : 0.1)),
                    .clear,
                ],
                center: UnitPoint(x: 0.5, y: 0.38),
                startRadius: 40,
                endRadius: 520
            )
            .ignoresSafeArea()
            .animation(.easeOut(duration: 2.0), value: phase)
        }
    }

    private var content: some View {
        VStack(spacing: 28) {
            Spacer()

            Text("badge_celebration_eyebrow")
                .font(.system(size: 11, weight: .semibold))
                .tracking(6)
                .foregroundStyle(
                    LinearGradient(
                        colors: [celebrationGlow, badge.color.opacity(colorScheme == .dark ? 0.85 : 0.9)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .opacity(phase == .initial ? 0 : 1)
                .animation(.easeOut(duration: 0.6).delay(0.45), value: phase)

            badgeHero
                .scaleEffect(phase == .initial ? 0.18 : 1.0)
                .opacity(phase == .initial ? 0 : 1)
                .animation(.spring(response: 0.72, dampingFraction: 0.52).delay(0.12), value: phase)

            VStack(spacing: 14) {
                Text(LocalizedStringKey(badge.labelKey))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(MornDashColors.labelPrimary(colorScheme))

                streakPill
            }
            .padding(.horizontal, 36)
            .opacity(phase == .initial ? 0 : 1)
            .offset(y: phase == .initial ? 16 : 0)
            .animation(.easeOut(duration: 0.6).delay(0.55), value: phase)

            Spacer()

            Button(action: onDismiss) {
                Text("badge_celebration_continue")
                    .font(.system(size: 15, weight: .semibold))
                    .tracking(1)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: buttonGradient,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: celebrationGlow.opacity(colorScheme == .dark ? 0.55 : 0.35), radius: 18, y: 8)
                    )
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 28)
            .opacity(phase == .settled ? 1 : 0)
            .offset(y: phase == .settled ? 0 : 20)
            .animation(.easeOut(duration: 0.5).delay(0.95), value: phase)
        }
    }

    private var badgeHero: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .stroke(celebrationGlow.opacity(colorScheme == .dark ? 0.28 : 0.38), lineWidth: 1.5)
                    .frame(width: 200 + CGFloat(i) * 36, height: 200 + CGFloat(i) * 36)
                    .scaleEffect(ringPulse ? 1.1 + CGFloat(i) * 0.04 : 1.0)
                    .opacity(ringPulse ? 0.0 : 0.85 - Double(i) * 0.2)
                    .animation(
                        .easeOut(duration: 1.8 + Double(i) * 0.4)
                            .repeatForever(autoreverses: false)
                            .delay(Double(i) * 0.45),
                        value: ringPulse
                    )
            }

            Circle()
                .fill(
                    RadialGradient(
                        colors: colorScheme == .dark
                            ? [badge.color.opacity(0.38), badge.color.opacity(0.05)]
                            : [accentTheme.idleColor.opacity(0.2), celebrationGlow.opacity(0.04)],
                        center: .center,
                        startRadius: 4,
                        endRadius: 110
                    )
                )
                .frame(width: 210, height: 210)
                .blur(radius: 22)
                .scaleEffect(glowBreath ? 1.06 : 0.94)
                .animation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true), value: glowBreath)

            Circle()
                .fill(colorScheme == .dark ? badge.color.opacity(0.14) : Color.white.opacity(0.94))
                .frame(width: 164, height: 164)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0 : 0.08), radius: 16, y: 6)
                .overlay(
                    Circle().strokeBorder(
                        LinearGradient(
                            colors: colorScheme == .dark
                                ? [badge.color.opacity(0.65), celebrationGlow.opacity(0.35)]
                                : [celebrationGlow.opacity(0.55), badge.color.opacity(0.35), accentGold.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                )

            Image(systemName: badge.icon)
                .font(.system(size: 72, weight: .regular))
                .foregroundStyle(
                    LinearGradient(
                        colors: iconGradient,
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0 : 0.12), radius: 10, y: 4)
                .shadow(color: celebrationGlow.opacity(colorScheme == .dark ? 0.65 : 0.3), radius: 20)
                .rotationEffect(.degrees(rotation))
                .symbolEffect(.bounce, value: phase == .burst)
        }
    }

    private var streakPill: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [celebrationGlow, accentGold],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            Text(streakLabel)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(MornDashColors.labelPrimary(colorScheme, opacity: 0.88))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(MornDashColors.fieldBackground(colorScheme))
                .overlay(
                    Capsule()
                        .strokeBorder(
                            LinearGradient(
                                colors: [celebrationGlow.opacity(0.45), badge.color.opacity(0.25)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }

    // MARK: - Helpers

    private var streakLabel: String {
        String(format: NSLocalizedString("streak_days_format", comment: ""), badge.threshold)
    }

    private func runIntro() {
        sparkleSeed = Int.random(in: 0..<10_000)
        withAnimation { phase = .burst }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            ringPulse = true
            glowBreath = true
        }
        withAnimation(.easeInOut(duration: 12).repeatForever(autoreverses: false)) {
            rotation = 10
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation { phase = .settled }
        }
    }
}
