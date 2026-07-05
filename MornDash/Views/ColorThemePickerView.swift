import SwiftUI

struct ColorThemePickerView: View {
    @AppStorage(AccentTheme.storageKey) private var accentThemeRaw = AccentTheme.default.rawValue
    @Environment(\.colorScheme) private var colorScheme

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]

    private var selectedAccentTheme: AccentTheme {
        AccentTheme(rawValue: accentThemeRaw) ?? .default
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("settings_color_theme_pro_only")
                    .font(.subheadline)
                    .foregroundColor(MornDashColors.secondaryText(colorScheme))
                    .fixedSize(horizontal: false, vertical: true)

                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(AccentTheme.allCases) { theme in
                        colorThemeOption(theme)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .mornDashScreenBackground()
    }

    private func colorThemeOption(_ theme: AccentTheme) -> some View {
        let isSelected = selectedAccentTheme == theme
        return Button {
            accentThemeRaw = theme.rawValue
        } label: {
            VStack(spacing: 10) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: theme.idleGradientColors,
                            startPoint: .bottomLeading,
                            endPoint: .topTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                isSelected ? Color.white.opacity(0.9) : Color.clear,
                                lineWidth: 2
                            )
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(
                                isSelected ? theme.idleColor : Color.clear,
                                lineWidth: 3
                            )
                            .padding(-3)
                    )
                    .shadow(color: theme.idleColor.opacity(isSelected ? 0.45 : 0.2), radius: isSelected ? 8 : 4)

                Text(theme.titleKey)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(
                        isSelected
                            ? MornDashColors.primaryText(colorScheme)
                            : MornDashColors.secondaryText(colorScheme, opacity: 0.7)
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
