import SwiftUI
import UIKit

enum AccentTheme: String, CaseIterable, Identifiable {
    case classic
    case sunrise
    case forest
    case ocean
    case lavender
    case rose

    static let storageKey = "mornDash_accent_theme"
    static let `default` = AccentTheme.classic

    var id: String { rawValue }

    var titleKey: LocalizedStringKey {
        switch self {
        case .classic: "settings_color_theme_classic"
        case .sunrise: "settings_color_theme_sunrise"
        case .forest: "settings_color_theme_forest"
        case .ocean: "settings_color_theme_ocean"
        case .lavender: "settings_color_theme_lavender"
        case .rose: "settings_color_theme_rose"
        }
    }

    var idleColor: Color {
        switch self {
        case .classic: .orange
        case .sunrise: Color(red: 1.0, green: 0.55, blue: 0.22)
        case .forest: Color(red: 0.35, green: 0.78, blue: 0.55)
        case .ocean: Color(red: 0.35, green: 0.65, blue: 0.95)
        case .lavender: Color(red: 0.65, green: 0.45, blue: 0.95)
        case .rose: Color(red: 1.0, green: 0.45, blue: 0.65)
        }
    }

    var idleGradientColors: [Color] {
        switch self {
        case .classic: [.orange, .yellow]
        case .sunrise: [Color(red: 1.0, green: 0.55, blue: 0.22), Color(red: 1.0, green: 0.78, blue: 0.35)]
        case .forest: [Color(red: 0.35, green: 0.78, blue: 0.55), Color(red: 0.55, green: 0.9, blue: 0.65)]
        case .ocean: [Color(red: 0.35, green: 0.65, blue: 0.95), Color(red: 0.45, green: 0.85, blue: 0.95)]
        case .lavender: [Color(red: 0.65, green: 0.45, blue: 0.95), Color(red: 0.8, green: 0.6, blue: 1.0)]
        case .rose: [Color(red: 1.0, green: 0.45, blue: 0.65), Color(red: 1.0, green: 0.65, blue: 0.78)]
        }
    }

    var blockingColor: Color {
        switch self {
        case .classic: .indigo
        case .sunrise: Color(red: 0.85, green: 0.32, blue: 0.12)
        case .forest: Color(red: 0.15, green: 0.45, blue: 0.38)
        case .ocean: Color(red: 0.2, green: 0.4, blue: 0.75)
        case .lavender: Color(red: 0.4, green: 0.25, blue: 0.7)
        case .rose: Color(red: 0.75, green: 0.2, blue: 0.45)
        }
    }

    var completedAccentColor: Color {
        switch self {
        case .classic: Color(red: 0.62, green: 0.92, blue: 0.74)
        case .sunrise: Color(red: 0.78, green: 0.88, blue: 0.42)
        case .forest: Color(red: 0.48, green: 0.88, blue: 0.62)
        case .ocean: Color(red: 0.45, green: 0.82, blue: 0.88)
        case .lavender: Color(red: 0.72, green: 0.62, blue: 0.95)
        case .rose: Color(red: 0.95, green: 0.62, blue: 0.78)
        }
    }

    /// Ambient glow when all tasks are completed for the day.
    var completedColor: Color {
        completedAccentColor.opacity(0.55)
    }

    /// Secondary ambient orb — complements the state-driven primary orb.
    var ambientSecondaryColor: Color {
        blockingColor
    }

    /// Active streak flame icon gradient.
    var streakFlameGradient: [Color] {
        let highlight = idleGradientColors.last ?? idleColor
        return [highlight, idleColor]
    }

    var streakFlameGradientStyle: LinearGradient {
        LinearGradient(colors: streakFlameGradient, startPoint: .top, endPoint: .bottom)
    }

    var uiAccent: UIColor {
        UIColor(idleColor)
    }

    /// Streak flames, emergency warnings, and similar emphasis gradients.
    var emphasisGradientColors: [Color] {
        [idleColor, blockingColor]
    }

    /// Light-mode ticket stub and similar two-stop idle gradients.
    var stubGradientColors: [Color] {
        let colors = idleGradientColors
        if colors.count >= 2 {
            return [colors[1], colors[0]]
        }
        return [idleColor.opacity(0.72), idleColor]
    }

    static func resolved(storedRaw: String, isPro: Bool) -> AccentTheme {
        guard isPro else { return .default }
        return AccentTheme(rawValue: storedRaw) ?? .default
    }
}

private struct AccentThemeKey: EnvironmentKey {
    static let defaultValue: AccentTheme = .default
}

extension EnvironmentValues {
    var accentTheme: AccentTheme {
        get { self[AccentThemeKey.self] }
        set { self[AccentThemeKey.self] = newValue }
    }
}

extension View {
    func accentTheme(_ theme: AccentTheme) -> some View {
        environment(\.accentTheme, theme)
    }
}
