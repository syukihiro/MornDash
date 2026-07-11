//
//  MornDashApp.swift
//  MornDash
//
//  Created by Yukihiro Sawada on 2026/01/14.
//

import SwiftUI
import FirebaseCore

@main
struct MornDashApp: App {
    @StateObject private var subscriptionManager = SubscriptionManager.shared

    init() {
        AppAppearance.configure(isDark: AppearanceMode.isDarkAtLaunch)
        FirebaseApp.configure()
        AnalyticsService.configureCollection()
        SubscriptionManager.shared.configure()
    }

    @AppStorage(AppearanceMode.storageKey) private var appearanceModeRaw = AppearanceMode.dark.rawValue
    @AppStorage(AccentTheme.storageKey) private var accentThemeRaw = AccentTheme.default.rawValue

    private var appearanceMode: AppearanceMode {
        AppearanceMode(rawValue: appearanceModeRaw) ?? .dark
    }

    private var resolvedAccentTheme: AccentTheme {
        AccentTheme.resolved(storedRaw: accentThemeRaw, isPro: subscriptionManager.isPro)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(appearanceMode.preferredColorScheme)
                .accentTheme(resolvedAccentTheme)
                .mornDashAppearanceSync()
                .environmentObject(subscriptionManager)
        }
    }
}
