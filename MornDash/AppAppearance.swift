import SwiftUI
import UIKit

enum AppAppearance {
    static func configure(isDark: Bool) {
        let background = isDark ? UIColor.black : UIColor(red: 0.98, green: 0.96, blue: 0.93, alpha: 1)
        let surface = isDark ? UIColor(white: 0.08, alpha: 1) : UIColor.white
        let tabBarBackground = isDark ? UIColor(white: 0.05, alpha: 1) : UIColor.white.withAlphaComponent(0.92)
        let navBarBackground = isDark ? UIColor.black : UIColor(red: 0.98, green: 0.96, blue: 0.93, alpha: 0.95)
        let titleColor = isDark ? UIColor.white : UIColor.label
        let unselectedTabTint = isDark
            ? UIColor.white.withAlphaComponent(0.45)
            : UIColor.secondaryLabel

        UITableView.appearance().backgroundColor = background
        UITableViewCell.appearance().backgroundColor = surface

        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = navBarBackground
        navAppearance.titleTextAttributes = [.foregroundColor: titleColor]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: titleColor]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().tintColor = .systemOrange

        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = tabBarBackground
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        UITabBar.appearance().unselectedItemTintColor = unselectedTabTint
        UITabBar.appearance().tintColor = .systemOrange
    }

    static func sync(mode: AppearanceMode, systemScheme: ColorScheme) {
        configure(isDark: mode.resolvesToDark(systemScheme: systemScheme))
    }
}

private struct MornDashScreenBackgroundModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .background(MornDashColors.screenBackground(colorScheme))
    }
}

private struct MornDashSheetBackgroundModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(MornDashColors.screenBackground(colorScheme).ignoresSafeArea())
    }
}

private struct MornDashNavigationBarModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .toolbarColorScheme(colorScheme, for: .navigationBar)
            .toolbarBackground(MornDashColors.navigationBarBackground(colorScheme), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
    }
}

private struct MornDashTabBarModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .toolbarColorScheme(colorScheme, for: .tabBar)
            .toolbarBackground(MornDashColors.tabBarBackground(colorScheme), for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
    }
}

extension View {
    func mornDashScreenBackground() -> some View {
        modifier(MornDashScreenBackgroundModifier())
    }

    func mornDashSheetBackground() -> some View {
        modifier(MornDashSheetBackgroundModifier())
    }

    func mornDashNavigationBarStyle() -> some View {
        modifier(MornDashNavigationBarModifier())
    }

    func mornDashTabBarStyle() -> some View {
        modifier(MornDashTabBarModifier())
    }

    func mornDashAppearanceSync() -> some View {
        modifier(MornDashAppearanceSyncModifier())
    }
}

private struct MornDashAppearanceSyncModifier: ViewModifier {
    @AppStorage(AppearanceMode.storageKey) private var appearanceModeRaw = AppearanceMode.dark.rawValue
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .onAppear { syncAppearance() }
            .onChange(of: appearanceModeRaw) { _, _ in syncAppearance() }
            .onChange(of: colorScheme) { _, _ in
                let mode = AppearanceMode(rawValue: appearanceModeRaw) ?? .dark
                if mode == .system {
                    syncAppearance()
                }
            }
    }

    private func syncAppearance() {
        let mode = AppearanceMode(rawValue: appearanceModeRaw) ?? .dark
        AppAppearance.sync(mode: mode, systemScheme: colorScheme)
    }
}
