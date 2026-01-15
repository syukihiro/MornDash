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
    
    @State private var showGlow = false         // 文字発光用
    @State private var selectedBlockMode: BlockMode = .morning // 設定画面用モード選択
    
    var body: some View {
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
            
            Task {
                await blockManager.requestAuthorization()
            }
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
            VStack(spacing: 0) {
                // ヘッダー
                HStack {
                    Text("Settings")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Button(action: {
                        viewModel.showAppPicker = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .font(.system(size: 30))
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                
                // 設定モード切替（Morning / Night）
                Picker("Mode", selection: $selectedBlockMode) {
                    ForEach(BlockMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.bottom, 10)
                
                // 時間設定 (Morning / Night 共通UI、バインディング切り替え)
                VStack(alignment: .leading, spacing: 5) {
                    Text(selectedBlockMode == .morning ? "Focus Duration" : "Wind Down Duration")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 5)
                    
                    Picker("Duration", selection: durationBinding) {
                        Text("3 min").tag(3)
                        Text("5 min").tag(5)
                        Text("10 min").tag(10)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .padding(.horizontal)
                .padding(.bottom)
                
                Divider()
                
                // スクリーンタイムAPIのピッカー (モードに応じてバインディングを切り替え)
                // FamilyActivityPickerはBindingを受け取るので、動的に切り替えるには工夫が必要
                // selectedBlockModeに応じて表示するピッカーを変える
                
                if selectedBlockMode == .morning {
                    FamilyActivityPicker(selection: $blockManager.morningSelection)
                } else {
                    FamilyActivityPicker(selection: $blockManager.sleepSelection)
                }
            }
            // システム背景色を使用して視認性を確保
            .background(Color(uiColor: .systemBackground))
        }
    }
    
    private var durationBinding: Binding<Int> {
        selectedBlockMode == .morning
            ? $viewModel.alarmSettings.blockDurationMinutes
            : $viewModel.alarmSettings.windDownDurationMinutes
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
