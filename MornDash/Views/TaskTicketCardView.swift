import SwiftUI

struct TaskTicketCardView: View {
    let task: TaskItem
    let index: Int
    let onPunch: () -> Void

    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    @State private var hasFiredMidHaptic: Bool = false
    @State private var showPunchBurst: Bool = false
    @State private var showPunchFlash: Bool = false

    private let cardHeight: CGFloat = 72
    private let stubWidth: CGFloat = 78
    private let cornerRadius: CGFloat = 10

    var body: some View {
        GeometryReader { geo in
            let trackWidth = geo.size.width
            let maxDrag = max(trackWidth - 80, 1)
            let progress = min(max(dragOffset / maxDrag, 0), 1)

            ZStack {
                ticketBackground

                if !task.isCompletedToday {
                    progressFill(width: dragOffset + 80)
                }

                ticketContent

                if !task.isCompletedToday {
                    slideHint(progress: progress)
                }

                if task.isCompletedToday {
                    punchedOverlay(in: geo.size)
                }

                if showPunchBurst {
                    PunchBurst()
                        .position(x: geo.size.width - 24, y: geo.size.height / 2)
                }

                if showPunchFlash {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.white.opacity(0.35))
                        .blendMode(.plusLighter)
                        .allowsHitTesting(false)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
            .simultaneousGesture(
                DragGesture(minimumDistance: 18)
                    .onChanged { value in
                        guard !task.isCompletedToday else { return }
                        if !isDragging {
                            guard abs(value.translation.width) > abs(value.translation.height) * 1.5 else { return }
                            isDragging = true
                        }
                        let raw = max(0, min(value.translation.width, maxDrag))
                        dragOffset = raw
                        if !hasFiredMidHaptic, raw / maxDrag >= 0.5 {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            hasFiredMidHaptic = true
                        }
                    }
                    .onEnded { _ in
                        guard !task.isCompletedToday else { return }
                        let wasDragging = isDragging
                        isDragging = false
                        guard wasDragging else { return }
                        if dragOffset / maxDrag >= 0.8 {
                            triggerPunch(maxDrag: maxDrag)
                        } else {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                dragOffset = 0
                            }
                            hasFiredMidHaptic = false
                        }
                    }
            )
        }
        .frame(height: cardHeight)
    }

    // MARK: - Subviews

    private var ticketBackground: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.white.opacity(task.isCompletedToday ? 0.04 : 0.10))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        .white.opacity(task.isCompletedToday ? 0.10 : 0.18),
                        style: StrokeStyle(lineWidth: 1, dash: [4, 3])
                    )
            )
    }

    private func progressFill(width: CGFloat) -> some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [Color.orange.opacity(0.45), Color.orange.opacity(0.05)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: max(width, 0))
            Spacer(minLength: 0)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    private var ticketContent: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(String(format: "No.%02d", index + 1))
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(task.isCompletedToday ? 0.4 : 0.6))
                Text(dateStamp)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(.leading, 14)
            .frame(width: stubWidth, alignment: .leading)

            DashedDivider()
                .frame(width: 1, height: cardHeight - 18)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(task.isCompletedToday ? .white.opacity(0.45) : .white)
                    .strikethrough(task.isCompletedToday, color: .white.opacity(0.5))
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if task.hasTimer, let seconds = task.timerDurationSeconds {
                    timerBadge(seconds: seconds)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            Spacer(minLength: 0)
        }
    }

    private func timerBadge(seconds: Int) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "timer")
            Text(TaskTimerFormatters.durationLabel(seconds: seconds))
        }
        .font(.system(size: 11, weight: .semibold))
        .foregroundColor(task.isCompletedToday ? .indigo.opacity(0.45) : .indigo.opacity(0.95))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.indigo.opacity(task.isCompletedToday ? 0.1 : 0.22))
        )
        .fixedSize()
    }

    private func slideHint(progress: CGFloat) -> some View {
        HStack(spacing: 1) {
            ForEach(0..<3) { i in
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundColor(
                        .orange.opacity(0.35 + 0.18 * Double(i) + 0.25 * progress)
                    )
            }
        }
        .padding(.trailing, 14)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private func punchedOverlay(in size: CGSize) -> some View {
        DoneStamp()
            .position(x: size.width * 0.6, y: size.height / 2)
    }

    // MARK: - Actions

    private func triggerPunch(maxDrag: CGFloat) {
        withAnimation(.spring(response: 0.22, dampingFraction: 0.6)) {
            dragOffset = maxDrag
        }
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

        showPunchBurst = true
        showPunchFlash = true
        withAnimation(.easeOut(duration: 0.18)) {
            showPunchFlash = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            onPunch()
            withAnimation(.easeOut(duration: 0.25)) {
                dragOffset = 0
            }
            hasFiredMidHaptic = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            showPunchBurst = false
        }
    }

    private var dateStamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: Date())
    }
}

private struct DashedDivider: View {
    var body: some View {
        GeometryReader { geo in
            Path { path in
                path.move(to: CGPoint(x: 0.5, y: 0))
                path.addLine(to: CGPoint(x: 0.5, y: geo.size.height))
            }
            .stroke(
                .white.opacity(0.28),
                style: StrokeStyle(lineWidth: 1, dash: [3, 3])
            )
        }
    }
}

private struct DoneStamp: View {
    @State private var scale: CGFloat = 1.8
    @State private var rotation: Double = -28
    @State private var opacity: Double = 0

    var body: some View {
        Text("DONE")
            .font(.system(size: 13, weight: .heavy, design: .monospaced))
            .tracking(3)
            .foregroundColor(.red.opacity(0.78))
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .overlay(
                Rectangle()
                    .stroke(.red.opacity(0.78), lineWidth: 1.5)
            )
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation))
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.5)) {
                    scale = 1.0
                    rotation = -12
                    opacity = 1
                }
            }
    }
}

private struct PunchBurst: View {
    @State private var progress: CGFloat = 0

    var body: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { i in
                let angle = Double(i) * (.pi * 2 / 8)
                Circle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 4, height: 4)
                    .offset(
                        x: CGFloat(cos(angle)) * 32 * progress,
                        y: CGFloat(sin(angle)) * 32 * progress
                    )
                    .opacity(Double(1 - progress))
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                progress = 1
            }
        }
    }
}
