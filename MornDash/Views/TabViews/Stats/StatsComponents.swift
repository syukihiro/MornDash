import SwiftUI

struct StatsSectionHeader: View {
    let icon: String
    let tint: Color
    let titleKey: LocalizedStringKey

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(tint)
            Text(titleKey)
                .font(.system(size: 11, weight: .medium))
                .tracking(2)
                .foregroundColor(.white.opacity(0.5))
        }
    }
}

struct StatsProLockBanner: View {
    let sectionTitleKey: LocalizedStringKey
    let titleKey: LocalizedStringKey
    let messageKey: LocalizedStringKey
    let buttonTitleKey: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                StatsSectionHeader(icon: "lock.fill", tint: .orange.opacity(0.85), titleKey: sectionTitleKey)

                Text(titleKey)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)

                Text(messageKey)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .semibold))
                    Text(buttonTitleKey)
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Capsule().fill(Color.orange))
                .padding(.top, 4)
            }
            .statsSectionCard(
                borderColor: .orange.opacity(0.18)
            )
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }
}

private struct StatsSectionCardModifier: ViewModifier {
    var borderColor: Color?

    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .overlay {
                        if let borderColor {
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(borderColor, lineWidth: 1)
                        }
                    }
            )
    }
}

extension View {
    func statsSectionCard(borderColor: Color? = nil) -> some View {
        modifier(StatsSectionCardModifier(borderColor: borderColor))
    }
}
