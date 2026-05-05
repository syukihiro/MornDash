//
//  MornDashApp.swift
//  MornDash
//
//  Created by Yukihiro Sawada on 2026/01/14.
//

import SwiftUI
import FirebaseCore

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
        SubscriptionManager.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark) // 常にダークモード（黒ベース）を強制
                .environmentObject(subscriptionManager)
        }
    }
}
