import Foundation
import FamilyControls
import ManagedSettings
import Combine

enum BlockMode: String, CaseIterable, Identifiable {
    case morning = "Morning"
    case sleep = "Night"
    
    var id: String { self.rawValue }
}

class BlockManager: ObservableObject {
    @Published var morningSelection = FamilyActivitySelection() {
        didSet { save(mode: .morning) }
    }
    
    @Published var sleepSelection = FamilyActivitySelection() {
        didSet { save(mode: .sleep) }
    }
    
    private let store = ManagedSettingsStore()
    private let morningKey = "BlockActivitySelection_Morning"
    private let sleepKey = "BlockActivitySelection_Sleep"
    private let oldKey = "BlockActivitySelection"
    
    init() {
        loadSelections()
    }
    
    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            print("Authorization successful")
        } catch {
            print("Authorization failed: \(error.localizedDescription)")
        }
    }
    
    func startBlocking(for mode: BlockMode) {
        let selection = (mode == .morning) ? morningSelection : sleepSelection
        print("Starting \(mode.rawValue) block with \(selection.applicationTokens.count) apps")
        
        store.shield.applications = selection.applicationTokens
        store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens
    }
    
    func stopBlocking() {
        print("Blocking stopped")
        store.clearAllSettings()
    }
    
    func save(mode: BlockMode) {
        let selection = (mode == .morning) ? morningSelection : sleepSelection
        let key = (mode == .morning) ? morningKey : sleepKey
        
        let encoder = PropertyListEncoder()
        do {
            let data = try encoder.encode(selection)
            UserDefaults.standard.set(data, forKey: key)
            print("\(mode.rawValue) selection saved")
        } catch {
            print("Failed to save \(mode.rawValue) selection: \(error)")
        }
    }
    
    func saveAll() {
        save(mode: .morning)
        save(mode: .sleep)
    }
    
    private func loadSelections() {
        let decoder = PropertyListDecoder()
        
        // Morning (Migrate old key if needed)
        if let data = UserDefaults.standard.data(forKey: morningKey) {
            if let selection = try? decoder.decode(FamilyActivitySelection.self, from: data) {
                self.morningSelection = selection
            }
        } else if let oldData = UserDefaults.standard.data(forKey: oldKey) {
            if let selection = try? decoder.decode(FamilyActivitySelection.self, from: oldData) {
                self.morningSelection = selection
            }
        }
        
        // Sleep
        if let data = UserDefaults.standard.data(forKey: sleepKey) {
            if let selection = try? decoder.decode(FamilyActivitySelection.self, from: data) {
                self.sleepSelection = selection
            }
        }
    }
}
