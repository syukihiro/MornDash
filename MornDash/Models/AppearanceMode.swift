import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    static let storageKey = "mornDash_appearance_mode"

    var id: String { rawValue }

    var titleKey: LocalizedStringKey {
        switch self {
        case .system: "settings_appearance_system"
        case .light: "settings_appearance_light"
        case .dark: "settings_appearance_dark"
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    static var current: AppearanceMode {
        AppearanceMode(rawValue: UserDefaults.standard.string(forKey: storageKey) ?? "") ?? .dark
    }

    static var isDarkAtLaunch: Bool {
        let systemIsDark = UITraitCollection.current.userInterfaceStyle == .dark
        return current.resolvesToDark(systemScheme: systemIsDark ? .dark : .light)
    }

    func resolvesToDark(systemScheme: ColorScheme) -> Bool {
        switch self {
        case .dark: return true
        case .light: return false
        case .system: return systemScheme == .dark
        }
    }
}
