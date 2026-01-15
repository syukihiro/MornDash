import Foundation
import AVFoundation
import AudioToolbox

class SoundManager: NSObject, AVAudioPlayerDelegate {
    static let shared = SoundManager()
    
    private var audioPlayer: AVAudioPlayer?
    private var vibrationTimer: Timer?
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            // マナーモード無視、他アプリの音を止める設定
            try session.setCategory(.playback, mode: .default, options: [.duckOthers])
            
            // 強制的にスピーカーから鳴らす
            try session.overrideOutputAudioPort(.speaker)
            
            try session.setActive(true)
        } catch {
            print("Audio setup failed: \(error)")
        }
    }
    
    func startAlarm(soundName: String) {
        // AlarmSound構造体から周波数を取得
        let sound = AlarmSound.all.first(where: { $0.name == soundName }) ?? AlarmSound.defaultSound
        let frequency = sound.frequency
        
        // WAVデータを生成して再生
        if let url = generateSineWaveWAV(frequency: frequency) {
            play(url: url)
        }
    }
    
    private func play(url: URL) {
        // 再生直前にもセッションを設定
        setupAudioSession()
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.numberOfLoops = -1 // 無限ループ
            audioPlayer?.volume = 1.0 // 最大音量
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            print("Playing generated sound")
        } catch {
            print("Play failed: \(error)")
        }
    }
    
    func stopAlarm() {
        audioPlayer?.stop()
        audioPlayer = nil
        stopVibration()
    }
    
    // プレビュー再生（バイブレーションなし）
    func previewSound(soundName: String) {
        stopAlarm() // 既存の再生を停止
        
        let sound = AlarmSound.all.first(where: { $0.name == soundName }) ?? AlarmSound.defaultSound
        let frequency = sound.frequency
        
        if let url = generateSineWaveWAV(frequency: frequency) {
            setupAudioSession()
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.numberOfLoops = -1 // ループ再生（停止ボタンで止める）
                audioPlayer?.volume = 1.0
                audioPlayer?.prepareToPlay()
                audioPlayer?.play()
            } catch {
                print("Preview failed: \(error)")
            }
        }
    }
    
    // バイブレーション開始（1秒おきに振動）
    func startVibration() {
        // 初回振動
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        
        // タイマーで繰り返し振動させる
        vibrationTimer?.invalidate()
        vibrationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }
    }
    
    // バイブレーション停止
    func stopVibration() {
        vibrationTimer?.invalidate()
        vibrationTimer = nil
    }
    
    // 通知用サウンドを準備する（アプリ起動時や設定変更時に呼ぶ）
    func prepareNotificationSound(soundName: String) {
        // Library/Sounds ディレクトリを取得（作成）
        guard let soundsDir = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first?.appendingPathComponent("Sounds") else { return }
        
        do {
            try FileManager.default.createDirectory(at: soundsDir, withIntermediateDirectories: true, attributes: nil)
            
            let soundURL = soundsDir.appendingPathComponent("alarm_sound.wav")
            
            // 選択されたサウンドの周建数を取得
            let sound = AlarmSound.all.first(where: { $0.name == soundName }) ?? AlarmSound.defaultSound
            let frequency = sound.frequency
            
            // 既に存在しても上書き更新する
            // 30秒の音声を生成
            _ = generateSineWaveWAV(frequency: frequency, duration: 30.0, outputURL: soundURL)
            print("Notification sound updated for [\(soundName)] at: \(soundURL)")
        } catch {
            print("Failed to prepare notification sound: \(error)")
        }
    }

    // 正弦波のWAVファイルを生成する
    // AVAudioFileを使用して正しくフォーマットされたWAVファイルを生成する
    private func generateSineWaveWAV(frequency: Double, duration: Double = 1.0, outputURL: URL? = nil) -> URL? {
        let sampleRate = 44100.0
        // 通知音制限(30秒)を考慮して、最大29秒に制限する
        let safeDuration = min(duration, 29.0)
        let frameCount = AVAudioFrameCount(sampleRate * safeDuration)
        
        let url: URL
        if let output = outputURL {
            url = output
        } else {
            let tempDir = FileManager.default.temporaryDirectory
            url = tempDir.appendingPathComponent("generated_alarm.wav")
        }
        
        // 設定: 16bit Linear PCM (WAV) - 最も互換性が高い
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false
        ]
        
        do {
            // 既存ファイルがある場合は削除
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
            
            let file = try AVAudioFile(forWriting: url, settings: settings, commonFormat: .pcmFormatInt16, interleaved: true)
            
            guard let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: frameCount) else { return nil }
            buffer.frameLength = frameCount
            
            if let channelData = buffer.int16ChannelData {
                let amplitude = 0.5
                let maxValue = 32767.0
                
                for i in 0..<Int(frameCount) {
                    let t = Double(i) / sampleRate
                    
                    // ピー・ピー・ピーという断続音にするために振幅変調
                    let envelope = sin(t * 10 * .pi) > 0 ? 1.0 : 0.0
                    let sample = Int16(amplitude * envelope * sin(2.0 * .pi * frequency * t) * maxValue)
                    
                    channelData[0][i] = sample
                }
            }
            
            try file.write(from: buffer)
            print("WAV file generated successfully at: \(url)")
            return url
        } catch {
            print("WAV generation failed: \(error)")
            return nil
        }
    }
    
    // intToByteArrayは不要になったため削除
}
