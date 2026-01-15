import Foundation
import Combine

enum AppState {
    case standby    // 待機中（時計表示）
    case editing    // 時刻編集中
    case ringing    // 鳴動中
    case snoozed    // スヌーズ中
    case blocking   // ブロック実行中
    case windDown   // おやすみ前の3分間ブロック
    case sleeping   // おやすみ中（3分経過後、ブロックなし、画面維持）
}

class HomeViewModel: ObservableObject {
    @Published var alarmSettings: AlarmSettings
    @Published var currentTime: Date = Date()
    @Published var showAppPicker = false
    @Published var appState: AppState = .standby
    @Published var remainingBlockTime: Int = 0 
    @Published var remainingSnoozeTime: Int = 0
    @Published var remainingWindDownTime: Int = 0
    
    private var cancellables = Set<AnyCancellable>()
    private let SNOOZE_DURATION = 540 // 9分 = 540秒
    // private let WIND_DOWN_DURATION = 180 // 3分
    
    // ※iOS制限により、バックグラウンドからの全画面起動は不可。
    // 「アプリを開いたまま枕元に置く」スタイルを推奨する。
    let keepOpenMessage = "For full alarm experience, keep the app open."
    
    init() {
        self.alarmSettings = AlarmSettings.load()
        
        // 通知用サウンドファイルの準備（Library/Soundsへ保存）
        SoundManager.shared.prepareNotificationSound(soundName: alarmSettings.soundName)
        
        // 通知許可をリクエスト
        NotificationManager.shared.requestAuthorization()
        
        setupSubscriptions()
        startTimer()
    }
    
    private func setupSubscriptions() {
        $alarmSettings
            .dropFirst()
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { settings in
                settings.save()
                
                // 設定変更時にサウンドファイルを更新（選択された音色で再生成）
                SoundManager.shared.prepareNotificationSound(soundName: settings.soundName)
                
                // 通知の更新
                if settings.isEnabled {
                    print("Scheduling notification for: \(settings.time)")
                    NotificationManager.shared.scheduleAlarm(at: settings.time)
                } else {
                    print("Canceling notification")
                    NotificationManager.shared.cancelAlarm()
                }
            }
            .store(in: &cancellables)
    }
    
    private func startTimer() {
        Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.tick()
            }
            .store(in: &cancellables)
    }
    
    private func tick() {
        currentTime = Date()
        
        switch appState {
        case .standby, .editing:
            // Slide to Sleep（おやすみモード）を実行していない場合はアラームを鳴らさない
            break
        case .snoozed:
            updateSnoozeTimer()
        case .blocking:
            updateBlockTimer()
        case .windDown:
            // おやすみ中もアラームチェックは必要（3分以内に指定時刻になった場合など）
            checkAlarm()
            updateWindDownTimer()
        case .sleeping:
            checkAlarm()
        default:
            break
        }
    }
    
    private func checkAlarm() {
        let calendar = Calendar.current
        let currentComponents = calendar.dateComponents([.hour, .minute, .second], from: currentTime)
        let alarmComponents = calendar.dateComponents([.hour, .minute], from: alarmSettings.time)
        
        if currentComponents.hour == alarmComponents.hour &&
            currentComponents.minute == alarmComponents.minute {
            
            // アプリ再起動時などの二重発火防止
            if let lastRing = alarmSettings.lastRingDate {
                // 分単位まで一致していたら、既に鳴らしたとみなしてスキップ
                if calendar.isDate(lastRing, equalTo: currentTime, toGranularity: .minute) {
                    return
                }
            }
            
            startRinging()
        }
    }
    
    private func startRinging() {
        appState = .ringing
        
        // 最後に鳴らした時刻を記録（二重発火防止）
        alarmSettings.lastRingDate = Date()
        // Combineのsink経由で保存されるが、念のため
        
        // サウンド再生
        SoundManager.shared.startAlarm(soundName: alarmSettings.soundName)
        
        // バイブレーション開始
        SoundManager.shared.startVibration()
    }
    
    // スヌーズ開始
    func snoozeAlarm() {
        SoundManager.shared.stopAlarm()
        // バイブレーション停止（stopAlarm内で呼ばれるが明示的に書くならここも確認）
        appState = .snoozed
        remainingSnoozeTime = SNOOZE_DURATION
    }
    
    private func updateSnoozeTimer() {
        if remainingSnoozeTime > 0 {
            remainingSnoozeTime -= 1
        } else {
            // スヌーズ終了 -> 再度鳴動
            startRinging()
        }
    }
    
    // アラーム停止＆ブロック開始
    func stopAlarmAndStartBlock(blockManager: BlockManager) {
        SoundManager.shared.stopAlarm()
        
        // アラーム設定をOFFにする（これによりローカル通知もキャンセルされる）
        alarmSettings.isEnabled = false
        
        
        appState = .blocking
        remainingBlockTime = alarmSettings.blockDurationMinutes * 60
        
        // スクリーンタイム制限開始
        blockManager.startBlocking(for: .morning)
    }
    
    private func updateBlockTimer() {
        if remainingBlockTime > 0 {
            remainingBlockTime -= 1
        } else {
            finishBlocking()
        }
    }
    
    private func finishBlocking() {
        appState = .standby
    }
    
    // おやすみスタート
    func startWindDown(blockManager: BlockManager) {
        remainingWindDownTime = alarmSettings.windDownDurationMinutes * 60
        appState = .windDown
        
        // アラームをONにする
        if !alarmSettings.isEnabled {
            alarmSettings.isEnabled = true
        }
        
        // 即座にブロック開始
        blockManager.startBlocking(for: .sleep)
    }
    
    private func updateWindDownTimer() {
        if remainingWindDownTime > 0 {
            remainingWindDownTime -= 1
        } else {
            // 3分経過後はsleepingに移行（画面は維持するが、ContentView側で非ブロックになる）
            appState = .sleeping
        }
    }
    
    // おやすみモード中断
    func cancelWindDown() {
        appState = .standby
    }
    
    // アラームON/OFFトグル
    func toggleAlarm() {
        alarmSettings.isEnabled.toggle()
    }
}
