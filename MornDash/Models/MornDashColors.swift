import SwiftUI

/// Dark mode keeps the original black + white glass aesthetic.
/// Light mode uses a warm "morning dawn" palette with strong contrast.
enum MornDashColors {
    // MARK: - Light palette

    private static let lightCanvas = Color(red: 0.98, green: 0.96, blue: 0.93)
    private static let lightCanvasAccent = Color(red: 0.99, green: 0.94, blue: 0.88)
    private static let lightSurface = Color.white
    private static let lightSurfaceMuted = Color(red: 0.97, green: 0.95, blue: 0.92)
    private static let lightInk = Color(red: 0.11, green: 0.10, blue: 0.16)
    private static let lightInkSecondary = Color(red: 0.38, green: 0.36, blue: 0.44)
    private static let lightInkTertiary = Color(red: 0.52, green: 0.49, blue: 0.56)
    private static let lightBorder = Color(red: 0.90, green: 0.87, blue: 0.83)
    private static let lightShadow = Color(red: 0.82, green: 0.62, blue: 0.38).opacity(0.14)

    // MARK: - Surfaces

    static func screenBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .black : lightCanvas
    }

    static func screenBackgroundGradient(_ scheme: ColorScheme) -> LinearGradient {
        if scheme == .dark {
            return LinearGradient(colors: [.black, .black], startPoint: .top, endPoint: .bottom)
        }
        return LinearGradient(
            colors: [lightCanvas, lightCanvasAccent, lightCanvas],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func navigationBarBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .black : lightCanvas.opacity(0.95)
    }

    static func tabBarBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.05) : lightSurface.opacity(0.92)
    }

    static func cardFill(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.05) : lightSurface
    }

    static func elevatedSurface(_ scheme: ColorScheme, active: Bool = true) -> Color {
        if scheme == .dark {
            return Color.white.opacity(active ? 0.10 : 0.04)
        }
        return active ? lightSurface : lightSurfaceMuted
    }

    static func listRowBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.04) : lightSurface
    }

    static func fieldBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.08) : lightSurfaceMuted
    }

    static func progressTrack(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.08) : lightBorder.opacity(0.65)
    }

    static func hairline(_ scheme: ColorScheme, active: Bool = true) -> Color {
        if scheme == .dark {
            return Color.white.opacity(active ? 0.18 : 0.10)
        }
        return active ? lightBorder : lightBorder.opacity(0.65)
    }

    static func divider(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.06) : lightBorder.opacity(0.85)
    }

    static func cardShadow(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .clear : lightShadow
    }

    // MARK: - Text

    static func labelPrimary(_ scheme: ColorScheme, opacity: Double = 1) -> Color {
        scheme == .dark ? .white.opacity(opacity) : lightInk.opacity(opacity)
    }

    static func labelSecondary(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .white.opacity(0.65) : lightInkSecondary
    }

    static func labelTertiary(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .white.opacity(0.45) : lightInkTertiary
    }

    static func labelMuted(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .white.opacity(0.35) : lightInkTertiary.opacity(0.85)
    }

    static func primaryText(_ scheme: ColorScheme, opacity: Double = 1) -> Color {
        labelPrimary(scheme, opacity: opacity)
    }

    static func secondaryText(_ scheme: ColorScheme, opacity: Double = 1) -> Color {
        scheme == .dark ? .white.opacity(opacity) : lightInkSecondary.opacity(opacity)
    }

    static func ticketText(_ scheme: ColorScheme, completed: Bool, prominent: Bool = true) -> Color {
        if scheme == .dark {
            if completed { return Color.white.opacity(prominent ? 0.45 : 0.4) }
            return prominent ? .white : Color.white.opacity(0.6)
        }
        if completed { return lightInkTertiary }
        return prominent ? lightInk : lightInkSecondary
    }

    static func ticketStubText(_ scheme: ColorScheme, completed: Bool) -> Color {
        if scheme == .dark {
            return Color.white.opacity(completed ? 0.4 : 0.6)
        }
        return completed ? lightInkTertiary : Color(red: 0.45, green: 0.22, blue: 0.06)
    }

    static func ticketStubGradient(_ scheme: ColorScheme, active: Bool, accent: AccentTheme = .default) -> LinearGradient {
        if scheme == .dark {
            return LinearGradient(
                colors: [Color.white.opacity(0.06), Color.white.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        if active {
            let colors = accent.stubGradientColors
            return LinearGradient(
                colors: colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        return LinearGradient(
            colors: [lightSurfaceMuted, lightSurfaceMuted],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static func inactiveIcon(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .white.opacity(0.35) : lightInkTertiary.opacity(0.55)
    }

    static func listSeparator(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.08) : lightBorder
    }

    static func flameInactiveGradient(_ scheme: ColorScheme) -> [Color] {
        scheme == .dark
            ? [.white.opacity(0.25), .white.opacity(0.15)]
            : [lightInkTertiary.opacity(0.35), lightInkTertiary.opacity(0.2)]
    }

    static let streakFlame = Color.red

    static func calendarEmptyDay(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.15) : lightBorder
    }

    static func calendarCellFill(_ scheme: ColorScheme, inMonth: Bool, isFuture: Bool) -> Color {
        if !inMonth { return .clear }
        if scheme == .dark {
            return Color.white.opacity(isFuture ? 0.04 : 0.08)
        }
        return isFuture ? lightSurfaceMuted.opacity(0.5) : lightSurface
    }

    static func contributionEmpty(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.03) : lightBorder.opacity(0.45)
    }

    static func contributionLow(_ scheme: ColorScheme, accent: AccentTheme = .default) -> Color {
        scheme == .dark ? Color.white.opacity(0.08) : accent.idleColor.opacity(0.22)
    }

    static func badgeLockedFill(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.04) : lightSurfaceMuted
    }

    static func periodPillSelectedFill(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.85) : lightInk
    }

    static func periodPillSelectedText(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .black : lightSurface
    }

    // MARK: - Onboarding / celebration / paywall

    static func onboardingGradientColors(_ scheme: ColorScheme) -> [Color] {
        if scheme == .dark {
            return [Color.black, Color(red: 0.08, green: 0.08, blue: 0.18)]
        }
        return [
            Color(red: 0.99, green: 0.97, blue: 0.94),
            Color(red: 0.98, green: 0.94, blue: 0.88),
        ]
    }

    static func onboardingProgressActive(_ scheme: ColorScheme, accent: AccentTheme = .default) -> Color {
        scheme == .dark ? .white : accent.idleColor
    }

    static func onboardingProgressInactive(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.18) : lightBorder
    }

    static func onboardingPrimaryButtonFill(_ scheme: ColorScheme, enabled: Bool, accent: AccentTheme = .default) -> Color {
        if !enabled {
            return scheme == .dark ? Color.white.opacity(0.3) : lightBorder
        }
        return scheme == .dark ? .white : accent.idleColor
    }

    static func onboardingPrimaryButtonText(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .black : .white
    }

    static func accentCardGradientEnd(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.04) : lightSurface
    }

    static func iconGradientLeading(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .white : lightInk
    }

    static func paywallGradientColors(_ scheme: ColorScheme) -> [Color] {
        if scheme == .dark {
            return [Color(red: 0.10, green: 0.06, blue: 0.02), .black]
        }
        return [
            Color(red: 1.0, green: 0.97, blue: 0.92),
            Color(red: 0.98, green: 0.96, blue: 0.93),
        ]
    }

    static func paywallFooterGradientColors(_ scheme: ColorScheme) -> [Color] {
        if scheme == .dark {
            return [Color.black.opacity(0), Color.black.opacity(0.85), .black]
        }
        return [
            lightCanvas.opacity(0),
            lightCanvas.opacity(0.92),
            lightCanvas,
        ]
    }

    static func celebrationBackdrop(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .black : lightCanvas
    }

    static func modalScrim(_ scheme: ColorScheme, opacity: Double = 0.45) -> Color {
        if scheme == .dark {
            return Color.black.opacity(opacity)
        }
        return lightInk.opacity(opacity * 0.35)
    }

    static func compactToastBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.12) : lightSurface
    }

    static func paywallPlanFill(_ scheme: ColorScheme, selected: Bool, accent: AccentTheme = .default) -> Color {
        if scheme == .dark {
            return Color.white.opacity(selected ? 0.08 : 0.04)
        }
        return selected ? accent.idleColor.opacity(0.08) : lightSurface
    }

    static func paywallPlanStroke(_ scheme: ColorScheme, selected: Bool, accent: AccentTheme = .default) -> Color {
        if scheme == .dark {
            return selected ? accent.idleColor.opacity(0.7) : Color.white.opacity(0.08)
        }
        return selected ? accent.idleColor.opacity(0.55) : lightBorder
    }
}

extension View {
    func mornDashCardShadow(_ scheme: ColorScheme) -> some View {
        shadow(
            color: MornDashColors.cardShadow(scheme),
            radius: scheme == .dark ? 0 : 10,
            x: 0,
            y: scheme == .dark ? 0 : 4
        )
    }
}
