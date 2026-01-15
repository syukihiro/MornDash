//
//  MornDashApp.swift
//  MornDash
//
//  Created by Yukihiro Sawada on 2026/01/14.
//

import SwiftUI

@main
struct MornDashApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark) // 常にダークモード（黒ベース）を強制
        }
    }
}
