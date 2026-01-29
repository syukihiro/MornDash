import Foundation

struct AlarmSound: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let frequency: Double
    let systemSoundName: String? // nilの場合は生成音を使用
    
    static let all: [AlarmSound] = [
        // Classical
        AlarmSound(id: "carmen", name: "Carmen Prelude", frequency: 0, systemSoundName: "Carmen_Prelude-Xy01-1(Fast)"),
        
        AlarmSound(id: "csikos", name: "Csikos Post", frequency: 0, systemSoundName: "Csikos_Post-Xy02-1(Fast)"),
        
        AlarmSound(id: "bumblebee", name: "Flight of the Bumblebee", frequency: 0, systemSoundName: "Flight_Of_The_Bumblebee-Xy01-2(Fast)"),
        
        AlarmSound(id: "gallop", name: "Grand Tournament Gallop", frequency: 0, systemSoundName: "Grand_Tournament_Gallop-Xy01-1(Fast)"),
        
        AlarmSound(id: "orpheus", name: "Orpheus", frequency: 0, systemSoundName: "Orpheus_In_The_Underworld-Xy02-1(Fast)"),
        
        AlarmSound(id: "polka", name: "Tritsch Tratsch Polka", frequency: 0, systemSoundName: "Tritsch_Tratsch_Polka-Xy01-2(Fast)"),
        
        // Relaxing & Atmospheric
        AlarmSound(id: "kokage", name: "Kokage De Yuttari", frequency: 0, systemSoundName: "Kokage_De_Yuttari-2(Fast)"),
        
        AlarmSound(id: "odayakana", name: "Odayakana Hitotoki", frequency: 0, systemSoundName: "Odayakana_Hitotoki-1(Fast)"),
        
        AlarmSound(id: "someday", name: "Someday in the Rain", frequency: 0, systemSoundName: "Someday in the Rain"),
        
        AlarmSound(id: "zattou", name: "Yoru no Zattou", frequency: 0, systemSoundName: "yoru no zattou"),
        
        // Pop & Others
        AlarmSound(id: "edit", name: "EDIT!", frequency: 0, systemSoundName: "EDIT!"),
        
        AlarmSound(id: "in_that_mood", name: "In That Mood", frequency: 0, systemSoundName: "In That Mood"),
        
        AlarmSound(id: "let_it_happen", name: "Let It Happen", frequency: 0, systemSoundName: "Let It Happen"),
        
        AlarmSound(id: "special_to_me", name: "Special To Me", frequency: 0, systemSoundName: "Special To Me"),
        
        AlarmSound(id: "soul_drive", name: "Soul Drive", frequency: 0, systemSoundName: "soul drive")
    ]
    
    static var defaultSound: AlarmSound {
        all[0] // Carmen Prelude
    }
}
