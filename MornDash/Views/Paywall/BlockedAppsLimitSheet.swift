import SwiftUI

enum BlockedAppsLimitReason {
    case appLimit
    case categories
}

struct BlockedAppsLimitSheet: View {
    let reason: BlockedAppsLimitReason
    let onUpgrade: () -> Void
    let onDismiss: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accentTheme) private var accentTheme

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: iconName)
                .font(.system(size: 44))
                .foregroundStyle(
                    LinearGradient(
                        colors: accentTheme.idleGradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(.top, 8)

            VStack(spacing: 10) {
                Text(titleKey)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(MornDashColors.labelPrimary(colorScheme))

                Text(messageKey)
                    .font(.system(size: 15))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .foregroundColor(MornDashColors.labelSecondary(colorScheme))
            }
            .padding(.horizontal, 8)

            VStack(spacing: 12) {
                Button(action: onUpgrade) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .semibold))
                        Text("settings_upgrade_to_pro")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(colorScheme == .dark ? .black : .white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        Capsule().fill(
                            LinearGradient(
                                colors: accentTheme.idleGradientColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    )
                }
                .buttonStyle(.plain)

                Button(action: onDismiss) {
                    Text(dismissKey)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(MornDashColors.labelSecondary(colorScheme))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 28)
        .frame(maxWidth: .infinity)
        .background(MornDashColors.screenBackground(colorScheme))
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private var iconName: String {
        switch reason {
        case .appLimit: return "app.badge.checkmark.fill"
        case .categories: return "square.grid.2x2.fill"
        }
    }

    private var titleKey: LocalizedStringKey {
        switch reason {
        case .appLimit:
            return "onboarding_apps_limit_title"
        case .categories:
            return "onboarding_apps_limit_categories_title"
        }
    }

    private var messageKey: LocalizedStringKey {
        switch reason {
        case .appLimit:
            return "onboarding_apps_limit_message"
        case .categories:
            return "onboarding_apps_limit_categories_message"
        }
    }

    private var dismissKey: LocalizedStringKey {
        switch reason {
        case .appLimit:
            return "onboarding_apps_limit_keep_free"
        case .categories:
            return "common_ok"
        }
    }
}
