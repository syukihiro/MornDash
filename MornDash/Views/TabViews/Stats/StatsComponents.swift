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

/// 記録タブ下部にまとめる Pro アップセル（比較レポート一式）
struct StatsProUpsellSection: View {
    let action: () -> Void

    private struct Feature: Identifiable {
        let id: String
        let icon: String
        let titleKey: LocalizedStringKey
        let messageKey: LocalizedStringKey
    }

    private let features: [Feature] = [
        Feature(id: "blocked", icon: "hourglass", titleKey: "stats_blocked_compare_lock_title", messageKey: "stats_blocked_compare_lock_message"),
        Feature(id: "task", icon: "chart.bar.doc.horizontal.fill", titleKey: "stats_task_compare_lock_title", messageKey: "stats_task_compare_lock_message"),
        Feature(id: "emergency", icon: "exclamationmark.triangle.fill", titleKey: "stats_emergency_compare_lock_title", messageKey: "stats_emergency_compare_lock_message"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StatsSectionHeader(icon: "lock.fill", tint: .orange.opacity(0.85), titleKey: "stats_pro_section_title")

            Text("stats_pro_section_upsell_desc")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.55))
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 0) {
                ForEach(Array(features.enumerated()), id: \.element.id) { index, feature in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: feature.icon)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.orange.opacity(0.85))
                            .frame(width: 20, alignment: .center)
                            .padding(.top, 2)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(feature.titleKey)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.9))
                            Text(feature.messageKey)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.5))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.vertical, 12)

                    if index < features.count - 1 {
                        Divider().background(Color.white.opacity(0.06))
                    }
                }
            }

            Button(action: action) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .semibold))
                    Text("stats_blocked_compare_unlock_button")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Capsule().fill(Color.orange))
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .statsSectionCard(borderColor: .orange.opacity(0.18))
        .frame(maxWidth: .infinity, alignment: .leading)
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
