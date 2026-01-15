import Foundation

struct AlarmSound: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let frequency: Double
    
    static let all: [AlarmSound] = [
        AlarmSound(id: "classic", name: "Classic", frequency: 600.0),
        AlarmSound(id: "digital", name: "Digital", frequency: 880.0),
        AlarmSound(id: "nature", name: "Nature", frequency: 440.0)
    ]
    
    static var defaultSound: AlarmSound {
        all[0]
    }
}
