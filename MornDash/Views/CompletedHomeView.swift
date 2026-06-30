import SwiftUI

struct CompletedHomeView: View {
    @ObservedObject var viewModel: HomeViewModel

    @State private var appeared = false
    @State private var displayedStreak = 0
    @State private var ringPulse = false
    @State private var glowBreath = false
    @State private var sparkleSeed = 0

    private let accentGreen = Color(red: 0.62, green: 0.92, blue: 0.74)
    private let accentGold = Color(red: 1.0, green: 0.88, blue: 0.55)

    private var streak: Int { viewModel.streakStore.currentStreak }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                streakHero
                    .padding(.top, 28)
                    .padding(.bottom, 32)

                weekProgressStrip
                    .padding(.horizontal, 28)
                    .padding(.bottom, 28)

                completedTasksCard
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)

                nextBlockFooter
                    .padding(.bottom, 40)
            }
            .frame(maxWidth: .infinity)
            .background(alignment: .top) {
                ambientGlow
            }
        }
        .onAppear {
            sparkleSeed = Int.random(in: 0..<10_000)
            withAnimation(.spring(response: 0.9, dampingFraction: 0.72)) {
                appeared = true
            }
            animateStreakCounter()
            ringPulse = true
            glowBreath = true
        }
    }

    // MARK: - Ambient

    private var ambientGlow: some View {
        ZStack {
            RadialGradient(
                colors: [
                    heroAccent.opacity(glowBreath ? 0.14 : 0.08),
                    heroAccent.opacity(0.04),
                    .clear,
                ],
                center: UnitPoint(x: 0.5, y: 0.36),
                startRadius: 0,
                endRadius: glowBreath ? 520 : 440
            )
            .animation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true), value: glowBreath)

            RadialGradient(
                colors: [accentGold.opacity(0.05), accentGold.opacity(0.015), .clear],
                center: UnitPoint(x: 0.5, y: 0.30),
                startRadius: 0,
                endRadius: 360
            )

            AmbientFloatingSparkles(
                seed: sparkleSeed,
                colors: [heroAccent, accentGold, .orange, .white],
                count: 14
            )
            .frame(height: 480)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 640)
        .mask(glowFadeMask)
        .allowsHitTesting(false)
    }

    private var glowFadeMask: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: .white.opacity(0.85), location: 0),
                .init(color: .white, location: 0.25),
                .init(color: .white.opacity(0.7), location: 0.55),
                .init(color: .white.opacity(0.25), location: 0.78),
                .init(color: .clear, location: 1.0),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Streak hero

    private var streakHero: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(heroAccent.opacity(0.06 - Double(i) * 0.015))
                    .frame(width: 200 + CGFloat(i) * 44, height: 200 + CGFloat(i) * 44)
                    .blur(radius: 8 + CGFloat(i) * 4)
                    .scaleEffect(ringPulse ? 1.14 + CGFloat(i) * 0.04 : 1.0)
                    .opacity(ringPulse ? 0.0 : 0.6 - Double(i) * 0.12)
                    .animation(
                        .easeOut(duration: 2.4 + Double(i) * 0.5)
                            .repeatForever(autoreverses: false)
                            .delay(Double(i) * 0.55),
                        value: ringPulse
                    )
            }

            Circle()
                .fill(
                    RadialGradient(
                        colors: [heroAccent.opacity(0.16), heroAccent.opacity(0.02)],
                        center: .center,
                        startRadius: 10,
                        endRadius: 110
                    )
                )
                .frame(width: 200, height: 200)
                .blur(radius: 32)
                .scaleEffect(glowBreath ? 1.08 : 0.94)
                .animation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true), value: glowBreath)

            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 13, weight: .semibold))
                    Text("main_completed_eyebrow")
                        .font(.system(size: 13, weight: .bold))
                        .tracking(4)
                }
                .foregroundStyle(
                    LinearGradient(
                        colors: [accentGreen, accentGold],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : -8)

                Text("\(displayedStreak)")
                    .font(.system(size: 96, weight: .bold, design: .rounded))
                    .foregroundStyle(streakNumberGradient)
                    .shadow(color: heroAccent.opacity(0.2), radius: 16)
                    .contentTransition(.numericText())
                    .scaleEffect(appeared ? 1 : 0.3)
                    .opacity(appeared ? 1 : 0)

                Text("main_completed_streak_unit")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .tracking(6)
                    .foregroundColor(.white.opacity(0.55))
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 8)
            }
        }
        .frame(height: 280)
        .frame(maxWidth: .infinity)
    }

    private var streakNumberGradient: LinearGradient {
        LinearGradient(
            colors: streak >= 30
                ? [.white, accentGold.opacity(0.9)]
                : streak >= 7
                    ? [.white, accentGold.opacity(0.75)]
                    : [.white, accentGreen.opacity(0.7)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var heroAccent: Color {
        streak >= 30 ? accentGold : streak >= 7 ? Color.orange.opacity(0.85) : accentGreen
    }

    // MARK: - Week strip

    private var weekProgressStrip: some View {
        let days = viewModel.streakStore.recentDays(7)
        let completedCount = days.filter(\.completed).count

        return VStack(spacing: 12) {
            HStack(spacing: 0) {
                ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                    VStack(spacing: 6) {
                        ZStack {
                            if day.completed {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [accentGreen.opacity(0.85), accentGold.opacity(0.6)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 28, height: 28)
                                    .shadow(color: accentGreen.opacity(0.25), radius: 8)
                            } else {
                                Circle()
                                    .fill(Color.white.opacity(0.06))
                                    .frame(width: 28, height: 28)
                            }

                            if day.completed {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white.opacity(0.85))
                            }
                        }
                        .scaleEffect(appeared ? 1 : 0.5)
                        .opacity(appeared ? 1 : 0)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.65).delay(0.5 + Double(index) * 0.06),
                            value: appeared
                        )

                        Text(weekdayLabel(for: day.date))
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.white.opacity(0.35))
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            Text(String(format: NSLocalizedString("main_completed_week_progress", comment: ""), completedCount))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.45))
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.05), Color.white.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.45), value: appeared)
    }

    private func weekdayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("EEEEE")
        return formatter.string(from: date)
    }

    // MARK: - Tasks card

    private var completedTasksCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(viewModel.taskStore.tasks) { task in
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(accentGreen.opacity(0.65))
                    Text(task.title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.55))
                        .strikethrough(true, color: .white.opacity(0.3))
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.035))
        )
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(.easeOut(duration: 0.6).delay(0.55), value: appeared)
    }

    // MARK: - Footer

    private var nextBlockFooter: some View {
        HStack(spacing: 6) {
            Image(systemName: "sunrise.fill")
                .font(.system(size: 12))
                .foregroundColor(.orange.opacity(0.7))
            Text(String(format: NSLocalizedString("main_completed_next_block", comment: ""), startTimeString))
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.35))
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.5).delay(0.7), value: appeared)
    }

    private var startTimeString: String {
        String(format: "%02d:%02d", viewModel.config.startHour, viewModel.config.startMinute)
    }

    // MARK: - Animation

    private func animateStreakCounter() {
        guard streak > 0 else {
            displayedStreak = 0
            return
        }
        displayedStreak = 0
        let steps = min(streak, 20)
        let interval = 0.06
        for step in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4 + interval * Double(step)) {
                let value = streak * step / steps
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    displayedStreak = value
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4 + interval * Double(steps) + 0.05) {
            displayedStreak = streak
        }
    }
}

// MARK: - Ambient sparkles

private struct AmbientFloatingSparkles: View {
    let seed: Int
    let colors: [Color]
    let count: Int

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(0..<count, id: \.self) { i in
                    AmbientSparkle(
                        index: i,
                        seed: seed,
                        canvas: proxy.size,
                        color: colors[i % colors.count]
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }
}

private struct AmbientSparkle: View {
    let index: Int
    let seed: Int
    let canvas: CGSize
    let color: Color

    @State private var phase = false

    var body: some View {
        var rng = CelebrationSeededRandom(seed: UInt64(bitPattern: Int64(seed)) &* 31 &+ UInt64(index) &* 17 &+ 1)
        let x = rng.next() * canvas.width
        let y = rng.next() * min(canvas.height, 500)
        let size = 2 + rng.next() * 3
        let duration = 3.0 + rng.next() * 4.0
        let delay = rng.next() * 3.0
        let driftY: CGFloat = 20 + CGFloat(rng.next() * 30)

        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .shadow(color: color.opacity(0.3), radius: 3)
            .position(x: x, y: y)
            .opacity(phase ? 0.08 : 0.35)
            .offset(y: phase ? -driftY : driftY)
            .scaleEffect(phase ? 0.6 : 1.0)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: duration)
                        .repeatForever(autoreverses: true)
                        .delay(delay)
                ) {
                    phase = true
                }
            }
    }
}
