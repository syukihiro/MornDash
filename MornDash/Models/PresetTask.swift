import Foundation

enum PresetTask: String, CaseIterable, Identifiable {
    case stretch, water, face, teeth, bed, breakfast, meditate, journal, walk, read

    var id: String { rawValue }

    var localizationKey: String {
        "onboarding_preset_\(rawValue)"
    }

    var title: String {
        NSLocalizedString(localizationKey, comment: "")
    }

    var icon: String {
        switch self {
        case .stretch: return "figure.flexibility"
        case .water: return "drop.fill"
        case .face: return "face.smiling"
        case .teeth: return "mouth.fill"
        case .bed: return "bed.double.fill"
        case .breakfast: return "fork.knife"
        case .meditate: return "leaf.fill"
        case .journal: return "book.closed.fill"
        case .walk: return "figure.walk"
        case .read: return "text.book.closed.fill"
        }
    }
}
