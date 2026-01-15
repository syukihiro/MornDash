//
//  ContentView.swift
//  MornDash
//
//  Created by Yukihiro Sawada on 2026/01/14.
//

import SwiftUI
import FamilyControls // 必須

struct ContentView: View {
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var blockManager = BlockManager()
    
    // Onboarding Flag
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    @State private var showGlow = false         // 文字発光用
    // selectedBlockMode, previewingSound は SettingsView に移動したため削除
    
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
            // 1. Organic Ambient Background
            AmbientBackgroundView(color: colorForState)
                .ignoresSafeArea()
            
            // 2. Main Content
            VStack {
                // Header (Settings Icon) - Minimal
                if viewModel.appState == .standby {
                    HStack {
                        Spacer()
                        Button(action: {
                            viewModel.showAppPicker = true
                        }) {
                            Image(systemName: "gearshape") // Fillをやめて線画に
                                .font(.system(size: 24, weight: .light))
                                .foregroundColor(.white.opacity(0.6))
                                .padding()
                        }
                    }
                    .padding(.horizontal)
                } else {
                    Spacer().frame(height: 60)
                }
                
                Spacer()
                
                // Content Switching
                switch viewModel.appState {
                case .standby, .editing:
                    MainView(
                        viewModel: viewModel,
                        blockManager: blockManager,
                        colorForState: colorForState,
                        showGlow: showGlow
                    )
                case .ringing:
                    RingingView(
                        viewModel: viewModel,
                        blockManager: blockManager,
                        showGlow: showGlow
                    )
                case .snoozed:
                    SnoozedView(
                        viewModel: viewModel,
                        blockManager: blockManager,
                        showGlow: showGlow
                    )
                case .blocking:
                    BlockingView(viewModel: viewModel)
                case .windDown, .sleeping:
                    WindDownView(viewModel: viewModel)
                }
                
                Spacer()
            }
        }
        .onAppear {
            // Start Animations
            showGlow = true
            
            // 重要: 画面の自動ロック（スリープ）を無効化
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onChange(of: viewModel.appState) { _, newState in
            if newState == .standby || newState == .sleeping {
                blockManager.stopBlocking()
            }
        }
        .onChange(of: blockManager.morningSelection) { _, _ in
            blockManager.save(mode: .morning)
        }
        .onChange(of: blockManager.sleepSelection) { _, _ in
            blockManager.save(mode: .sleep)
        }
        .sheet(isPresented: $viewModel.showAppPicker, onDismiss: {
            blockManager.saveAll()
        }) {
            SettingsView(
                viewModel: viewModel,
                blockManager: blockManager,
                isPresented: $viewModel.showAppPicker
            )
        }
    }
    private var colorForState: Color {
        switch viewModel.appState {
        case .ringing: return .red
        case .blocking: return .indigo
        case .windDown, .sleeping: return .indigo
        case .snoozed: return .orange
        case .standby, .editing:
            return viewModel.alarmSettings.isEnabled ? .green : .gray
        }
    }
}

#Preview {
    ContentView()
}

