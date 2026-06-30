import SwiftUI

struct BadgeCelebrationView: View {
    let badge: Badge
    let streak: Int
    let onDismiss: () -> Void

    @State private var phase: AnimationPhase = .initial
    @State private var iconPulse = false
    @State private var rotation: Double = 0
    @State private var sparkleSeed: Int = 0

    private enum AnimationPhase {
        case initial
        case burst
        case settled
    }

    var body: some View {
        ZStack {
            backdrop
            sparkles
            content
        }
        .preferredColorScheme(.dark)
        .onAppear { runIntro() }
    }

    // MARK: - Layers

    private var backdrop: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            RadialGradient(
                colors: [badge.color.opacity(phase == .initial ? 0.0 : 0.55), .clear],
                center: .center,
                startRadius: 0,
                endRadius: phase == .initial ? 60 : 480
            )
            .ignoresSafeArea()
            .animation(.easeOut(duration: 1.6), value: phase)

            RadialGradient(
                colors: [badge.color.opacity(phase == .initial ? 0.0 : 0.18), .clear],
                center: .center,
                startRadius: 120,
                endRadius: 800
            )
            .ignoresSafeArea()
            .animation(.easeOut(duration: 2.2), value: phase)
        }
    }

    private var sparkles: some View {
        CelebrationSparkleField(
            seed: sparkleSeed,
            colors: [badge.color],
            active: phase != .initial,
            count: 22
        )
    }

    private var content: some View {
        VStack(spacing: 28) {
            Spacer()

            Text("badge_celebration_eyebrow")
                .font(.system(size: 11, weight: .semibold))
                .tracking(6)
                .foregroundColor(badge.color.opacity(0.9))
                .opacity(phase == .initial ? 0 : 1)
                .animation(.easeOut(duration: 0.6).delay(0.5), value: phase)

            ZStack {
                Circle()
                    .stroke(badge.color.opacity(0.25), lineWidth: 1)
                    .frame(width: 220, height: 220)
                    .scaleEffect(iconPulse ? 1.08 : 1.0)
                    .opacity(iconPulse ? 0.0 : 0.8)
                    .animation(.easeOut(duration: 1.6).repeatForever(autoreverses: false), value: iconPulse)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [badge.color.opacity(0.35), badge.color.opacity(0.05)],
                            center: .center,
                            startRadius: 4,
                            endRadius: 110
                        )
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: 20)

                Circle()
                    .fill(badge.color.opacity(0.15))
                    .frame(width: 160, height: 160)
                    .overlay(
                        Circle().strokeBorder(badge.color.opacity(0.5), lineWidth: 1)
                    )

                Image(systemName: badge.icon)
                    .font(.system(size: 76, weight: .regular))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, badge.color],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: badge.color.opacity(0.7), radius: 18)
                    .rotationEffect(.degrees(rotation))
            }
            .scaleEffect(phase == .initial ? 0.2 : 1.0)
            .opacity(phase == .initial ? 0 : 1)
            .animation(.spring(response: 0.7, dampingFraction: 0.55).delay(0.15), value: phase)

            VStack(spacing: 10) {
                Text(LocalizedStringKey(badge.labelKey))
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)

                Text(streakLabel)
                    .font(.system(size: 14, weight: .medium))
                    .tracking(2)
                    .foregroundColor(.white.opacity(0.65))
            }
            .padding(.horizontal, 40)
            .opacity(phase == .initial ? 0 : 1)
            .offset(y: phase == .initial ? 12 : 0)
            .animation(.easeOut(duration: 0.6).delay(0.6), value: phase)

            Spacer()

            Button(action: onDismiss) {
                Text("badge_celebration_continue")
                    .font(.system(size: 15, weight: .semibold))
                    .tracking(2)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(badge.color)
                            .shadow(color: badge.color.opacity(0.6), radius: 18, y: 8)
                    )
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 28)
            .opacity(phase == .settled ? 1 : 0)
            .offset(y: phase == .settled ? 0 : 20)
            .animation(.easeOut(duration: 0.5).delay(0.95), value: phase)
        }
    }

    // MARK: - Helpers

    private var streakLabel: String {
        String(format: NSLocalizedString("streak_days_format", comment: ""), badge.threshold)
    }

    private func runIntro() {
        sparkleSeed = Int.random(in: 0..<10_000)
        withAnimation { phase = .burst }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            iconPulse = true
        }
        withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: false)) {
            rotation = 360
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation { phase = .settled }
        }
    }
}
