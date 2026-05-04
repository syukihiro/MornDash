//
//  MornDashApp.swift
//  MornDash
//
//  Created by Yukihiro Sawada on 2026/01/14.
//

import SwiftUI

@main
struct MornDashApp: App {
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
