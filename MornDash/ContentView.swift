//
//  ContentView.swift
//  MornDash
//
//  Created by Yukihiro Sawada on 2026/01/14.
//

import SwiftUI
import FamilyControls

struct ContentView: View {
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var blockManager = BlockManager()

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @State private var showGlow = false
    @State private var selectedTab: Int = 0
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingView(
                    isCompleted: $hasCompletedOnboarding,
                    viewModel: viewModel,
                    blockManager: blockManager
                )
            } else {
                mainAppView
            }
        }
    }

    var mainAppView: some View {
        ZStack {
            AmbientBackgroundView(color: colorForState)
                .ignoresSafeArea()

            TabView(selection: $selectedTab) {
                homeTab
                    .tabItem {
                        Label("tab_home", systemImage: "house.fill")
                    }
                    .tag(0)

                TasksTabView(viewModel: viewModel)
                    .tabItem {
                        Label("tab_tasks", systemImage: "checklist")
                    }
                    .tag(1)

                StatsTabView(viewModel: viewModel, blockManager: blockManager)
                    .tabItem {
                        Label("tab_stats", systemImage: "chart.bar.fill")
                    }
                    .tag(2)

                SettingsView(viewModel: viewModel, blockManager: blockManager)
                    .tabItem {
                        Label("tab_settings", systemImage: "gearshape.fill")
                    }
                    .tag(3)
            }
            .tint(.orange)
        }
        .onAppear {
            showGlow = true
            viewModel.syncShield(blockManager: blockManager)
            viewModel.applySchedule(blockManager: blockManager)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                viewModel.syncShield(blockManager: blockManager)
            }
        }
        .fullScreenCover(item: $viewModel.pendingBadge) { badge in
            BadgeCelebrationView(
                badge: badge,
                streak: viewModel.streakStore.currentStreak,
                onDismiss: { viewModel.dismissPendingBadge() }
            )
        }
    }

    private var homeTab: some View {
        Group {
            if viewModel.appState == .blocking {
                BlockingView(viewModel: viewModel, blockManager: blockManager)
            } else {
                MainView(
                    viewModel: viewModel,
                    blockManager: blockManager,
                    colorForState: colorForState,
                    showGlow: showGlow
                )
            }
        }
    }

    private var colorForState: Color {
        switch viewModel.appState {
        case .blocking: return .indigo
        case .idle: return .orange
        }
    }
}

#Preview {
    ContentView()
}
