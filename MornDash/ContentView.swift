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
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

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
        .task {
            await subscriptionManager.refresh()
            blockManager.applyFreePlanCategoryRestrictionIfNeeded()
        }
        .onChange(of: subscriptionManager.isPro) { _, isPro in
            if !isPro {
                blockManager.applyFreePlanCategoryRestrictionIfNeeded()
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
                        Image(systemName: "house.fill")
                            .accessibilityLabel(Text("tab_home"))
                    }
                    .tag(0)

                TasksTabView(viewModel: viewModel)
                    .tabItem {
                        Image(systemName: "checklist")
                            .accessibilityLabel(Text("tab_tasks"))
                    }
                    .tag(1)

                StatsTabView(viewModel: viewModel, blockManager: blockManager)
                    .tabItem {
                        Image(systemName: "chart.bar.fill")
                            .accessibilityLabel(Text("tab_stats"))
                    }
                    .tag(2)

                SettingsView(viewModel: viewModel, blockManager: blockManager)
                    .tabItem {
                        Image(systemName: "gearshape.fill")
                            .accessibilityLabel(Text("tab_settings"))
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
        .fullScreenCover(isPresented: $viewModel.showRoutineCompleteCelebration) {
            RoutineCompleteCelebrationView(
                streak: viewModel.streakStore.currentStreak,
                style: viewModel.routineCelebrationStyle,
                onDismiss: { viewModel.dismissRoutineCompleteCelebration() }
            )
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
        case .idle:
            if !viewModel.taskStore.tasks.isEmpty && viewModel.taskStore.allCompletedToday {
                return Color(red: 0.62, green: 0.92, blue: 0.74).opacity(0.55)
            }
            return .orange
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(SubscriptionManager.shared)
}
