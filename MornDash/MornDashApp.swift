//
//  MornDashApp.swift
//  MornDash
//
//  Created by Yukihiro Sawada on 2026/01/14.
//

import SwiftUI
import FirebaseCore
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct MornDashApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var subscriptionManager = SubscriptionManager.shared

    init() {
        AppAppearance.configure(isDark: AppearanceMode.isDarkAtLaunch)
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
