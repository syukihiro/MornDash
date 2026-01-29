import SwiftUI
import FamilyControls

struct SettingsView: View {
    @ObservedObject var viewModel: HomeViewModel
    @ObservedObject var blockManager: BlockManager
    @Binding var isPresented: Bool
    
    @State private var selectedBlockMode: BlockMode = .morning
    @State private var previewingSound: String? = nil
    
    @State private var showAppSelection = false
    @State private var showSoundSelection = false

    var body: some View {
        VStack(spacing: 0) {
            // ... (Header)
            // ヘッダー
            HStack {
                Text("settings_title")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Button(action: {
                    SoundManager.shared.stopAlarm() // 閉じるときにプレビュー停止
                    previewingSound = nil
                    isPresented = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .symbolRenderingMode(.hierarchical)
                        .font(.system(size: 30))
                        .foregroundColor(.gray)
                }
            }
            .padding()
            
            ScrollView {
                VStack(spacing: 20) {
                    
                    // 設定モード切替（Morning / Night）
                    Picker("Mode", selection: $selectedBlockMode) {
                        ForEach(BlockMode.allCases) { mode in
                            Text(LocalizedStringKey(mode.rawValue)).tag(mode)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // 時間設定
                    VStack(alignment: .leading, spacing: 5) {
                        Text(selectedBlockMode == .morning ? LocalizedStringKey("settings_focus_duration") : LocalizedStringKey("settings_wind_down_duration"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading, 5)
                        
                        Picker("Duration", selection: durationBinding) {
                            Text("time_3_min").tag(3)
                            Text("time_5_min").tag(5)
                            Text("time_10_min").tag(10)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    .padding(.horizontal)
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // サウンド選択ボタン
                    VStack(alignment: .leading, spacing: 10) {
                        Text("settings_alarm_sound")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading, 20)
                        
                        Button(action: {
                            showSoundSelection = true
                        }) {
                            HStack {
                                Text(viewModel.alarmSettings.soundName)
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("common_select")
                                    .foregroundColor(.secondary)
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color(uiColor: .secondarySystemBackground))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // アプリ選択ボタン
                    Button(action: {
                        showAppSelection = true
                    }) {
                        HStack {
                            Text("settings_blocked_apps")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Spacer()
                            Text("common_select")
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemBackground))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // クレジット (OtoLogic)
                    VStack(spacing: 5) {
                        Text("settings_credit_title")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Link(destination: URL(string: "https://otologic.jp")!) {
                            Text("settings_credit_otologic")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.bottom, 20)
                }
                .padding(.bottom, 20)
            }
        }
        // システム背景色を使用して視認性を確保
        .background(Color(uiColor: .systemBackground))
        .sheet(isPresented: $showAppSelection) {
            VStack {
                HStack {
                    Text(selectedBlockMode == .morning ? LocalizedStringKey("settings_morning_block") : LocalizedStringKey("settings_sleep_block"))
                        .font(.headline)
                        .padding(.leading)
                    Spacer()
                    Button("common_done") {
                        showAppSelection = false
                    }
                    .padding()
                }
                
                if selectedBlockMode == .morning {
                    FamilyActivityPicker(selection: $blockManager.morningSelection)
                } else {
                    FamilyActivityPicker(selection: $blockManager.sleepSelection)
                }
            }
        }
        .sheet(isPresented: $showSoundSelection) {
            SoundSelectionView(viewModel: viewModel, isPresented: $showSoundSelection)
        }
    }
    
    private var durationBinding: Binding<Int> {
        selectedBlockMode == .morning
            ? $viewModel.alarmSettings.blockDurationMinutes
            : $viewModel.alarmSettings.windDownDurationMinutes
    }
}

struct SoundSelectionView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Binding var isPresented: Bool
    @State private var previewingSound: String? = nil
    
    var body: some View {
        VStack {
            // Header
            HStack {
                Text("settings_alarm_sound")
                    .font(.headline)
                Spacer()
                Button("common_done") {
                    SoundManager.shared.stopAlarm()
                    isPresented = false
                }
            }
            .padding()
            
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(AlarmSound.all) { sound in
                        HStack {
                            Button(action: {
                                viewModel.alarmSettings.soundName = sound.name
                            }) {
                                HStack {
                                    Text(sound.name)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if viewModel.alarmSettings.soundName == sound.name {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            
                            // プレビューボタン
                            Button(action: {
                                if previewingSound == sound.name {
                                    SoundManager.shared.stopAlarm()
                                    previewingSound = nil
                                } else {
                                    SoundManager.shared.previewSound(soundName: sound.name)
                                    previewingSound = sound.name
                                }
                            }) {
                                Image(systemName: (previewingSound == sound.name) ? "stop.circle.fill" : "play.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                            }
                            .padding(.leading, 10)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color(uiColor: .systemBackground))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
