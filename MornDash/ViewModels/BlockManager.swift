import Foundation
import FamilyControls
import ManagedSettings
import Combine // 必須: ObservableObjectと@Publishedに必要

class BlockManager: ObservableObject {
    // ユーザーが選択したブロック対象のアプリ・カテゴリ
    @Published var activitySelection = FamilyActivitySelection() {
        didSet {
            saveSelection()
        }
    }
    
    // シールド設定を管理するストア
    private let store = ManagedSettingsStore()
    private let userDefaultsKey = "BlockActivitySelection"
    
    init() {
        loadSelection()
    }
    
    // スクリーンタイムAPIの認可リクエスト
    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            print("Authorization successful")
        } catch {
            print("Authorization failed: \(error.localizedDescription)")
        }
    }
    
    // ブロックを実行（シールド適用）
    func startBlocking() {
        // 選択されたアプリ・カテゴリに対してシールドを適用
        print("Starting block with \(activitySelection.applicationTokens.count) apps")
        
        // アプリ、カテゴリ、ウェブドメインを制限対象に設定
        store.shield.applications = activitySelection.applicationTokens
        store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(activitySelection.categoryTokens)
        store.shield.webDomains = activitySelection.webDomainTokens
    }
    
    // ブロック解除
    func stopBlocking() {
        print("Blocking stopped")
        store.clearAllSettings()
    }
    
    // 保存
    private func saveSelection() {
        let encoder = PropertyListEncoder()
        if let data = try? encoder.encode(activitySelection) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
            print("Selection saved")
        }
    }
    
    // 読み込み
    private func loadSelection() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else { return }
        let decoder = PropertyListDecoder()
        if let selection = try? decoder.decode(FamilyActivitySelection.self, from: data) {
            self.activitySelection = selection
            print("Selection loaded: \(selection.applicationTokens.count) apps")
        }
    }
}
