import SwiftUI

struct EmergencyUnlockView: View {
    @ObservedObject var viewModel: HomeViewModel
    @ObservedObject var blockManager: BlockManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accentTheme) private var accentTheme

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 28) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color.white.opacity(0.08)))
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                Spacer(minLength: 0)

                VStack(spacing: 18) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 64, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: accentTheme.emphasisGradientColors,
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .red.opacity(0.4), radius: 24)

                    Text("emergency_unlock_title")
                        .font(.system(size: 22, weight: .bold))
                        .tracking(1)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("emergency_unlock_subtitle")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                VStack(alignment: .leading, spacing: 14) {
                    bulletRow(icon: "calendar", text: NSLocalizedString("emergency_unlock_bullet_today", comment: ""))
                    bulletRow(icon: "sunrise.fill", text: NSLocalizedString("emergency_unlock_bullet_tomorrow", comment: ""))
                    bulletRow(icon: "flame.fill", text: NSLocalizedString("emergency_unlock_bullet_streak", comment: ""))
                }
                .padding(20)
                .frame(maxWidth: 340)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(accentTheme.idleColor.opacity(0.2), lineWidth: 1)
                        )
                )

                Spacer(minLength: 0)

                VStack(spacing: 14) {
                    SlideToPerformView(
                        label: NSLocalizedString("emergency_unlock_slide_label", comment: ""),
                        icon: "lock.open.fill",
                        color: .red,
                        action: confirmUnlock
                    )
                    .padding(.horizontal, 24)

                    Button(action: { dismiss() }) {
                        Text("emergency_unlock_cancel")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.vertical, 10)
                    }
                }
                .padding(.bottom, 24)
            }
        }
    }

    private func bulletRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(accentTheme.idleColor.opacity(0.85))
                .frame(width: 20)
                .padding(.top, 2)
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func confirmUnlock() {
        viewModel.giveUp(blockManager: blockManager)
        dismiss()
    }
}
