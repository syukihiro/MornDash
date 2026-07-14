//
//  ContentView.swift
//  MornDash
//
//  Created by Yukihiro Sawada on 2026/01/14.
//

import SwiftUI
import FamilyControls
import StoreKit

struct ContentView: View {
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var blockManager = BlockManager()

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hasShownPostOnboardingPaywall") private var hasShownPostOnboardingPaywall = false

    @State private var showGlow = false
    @State private var selectedTab: Int = 0
    @State private var showPostOnboardingPaywall = false
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.requestReview) private var requestReview
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @Environment(\.accentTheme) private var accentTheme

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
            await AnalyticsService.waitUntilConfigured()
            subscriptionManager.syncFirebaseAttribution()
            await subscriptionManager.refresh()
            blockManager.applyFreePlanCategoryRestrictionIfNeeded()
        }
        .onChange(of: subscriptionManager.isPro) { _, isPro in
            if !isPro {
                blockManager.applyFreePlanCategoryRestrictionIfNeeded()
            }
        }
        .onChange(of: hasCompletedOnboarding) { _, completed in
            guard completed, !subscriptionManager.isPro, !hasShownPostOnboardingPaywall else { return }
            hasShownPostOnboardingPaywall = true
            showPostOnboardingPaywall = true
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
            .tint(accentTheme.idleColor)
            .mornDashTabBarStyle()
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
        .fullScreenCover(isPresented: $viewModel.showRoutineCompleteCelebration, onDismiss: maybeRequestReview) {
            RoutineCompleteCelebrationView(
                streak: viewModel.streakStore.currentStreak,
                style: viewModel.routineCelebrationStyle,
                badge: viewModel.celebrationBadge,
                onDismiss: { viewModel.dismissRoutineCompleteCelebration() }
            )
        }
        .fullScreenCover(item: $viewModel.pendingBadge, onDismiss: maybeRequestReview) { badge in
            BadgeCelebrationView(
                badge: badge,
                streak: viewModel.streakStore.currentStreak,
                onDismiss: { viewModel.dismissPendingBadge() }
            )
        }
        .paywallFullScreenCover(isPresented: $showPostOnboardingPaywall, source: .onboarding)
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

    /// 完了/バッジのセレブレーションが閉じ切った後、ストリーク節目なら App Store 評価を求める。
    private func maybeRequestReview() {
        guard let milestone = viewModel.consumeReviewPromptIfReady() else { return }
        AnalyticsService.logReviewRequested(milestone: milestone)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            requestReview()
        }
    }

    private var colorForState: Color {
        switch viewModel.appState {
        case .blocking: return accentTheme.blockingColor
        case .idle:
            if !viewModel.taskStore.tasks.isEmpty && viewModel.taskStore.allCompletedToday {
                return accentTheme.completedColor
            }
            return accentTheme.idleColor
        }
    }
}

#Preview {
    ContentView()
        .accentTheme(.classic)
        .environmentObject(SubscriptionManager.shared)
}
