import Foundation

struct AlarmSound: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let frequency: Double
    let systemSoundName: String? // nilの場合は生成音を使用
    
    static let all: [AlarmSound] = [
        // Custom Generated Sounds
        AlarmSound(id: "classic", name: "Classic", frequency: 600.0, systemSoundName: nil),
        AlarmSound(id: "digital", name: "Digital", frequency: 880.0, systemSoundName: nil),
        AlarmSound(id: "nature", name: "Nature", frequency: 440.0, systemSoundName: nil),
        
        // System Sounds (AlarmKit)
        AlarmSound(id: "radar", name: "Radar", frequency: 0, systemSoundName: "Radar"),
        AlarmSound(id: "apex", name: "Apex", frequency: 0, systemSoundName: "Apex"),
        AlarmSound(id: "beacon", name: "Beacon", frequency: 0, systemSoundName: "Beacon"),
        AlarmSound(id: "chime", name: "Chime", frequency: 0, systemSoundName: "Chime"),
        AlarmSound(id: "circuit", name: "Circuit", frequency: 0, systemSoundName: "Circuit"),
        AlarmSound(id: "constellation", name: "Constellation", frequency: 0, systemSoundName: "Constellation"),
        AlarmSound(id: "scifi", name: "Sci-Fi", frequency: 0, systemSoundName: "Sci-Fi") // 仮の名称
    ]
    
    static var defaultSound: AlarmSound {
        all[0]
    }
}
