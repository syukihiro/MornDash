import Foundation
import SwiftUI

enum PresetTask: String, CaseIterable, Identifiable {
    case stretch, bed, meditate, journal, read, run

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
        case .bed: return "bed.double.fill"
        case .meditate: return "leaf.fill"
        case .journal: return "book.closed.fill"
        case .read: return "text.book.closed.fill"
        case .run: return "figure.run"
        }
    }

    var accentColor: Color {
        switch self {
        case .stretch: return Color(red: 0.35, green: 0.85, blue: 0.95)
        case .bed: return Color(red: 0.55, green: 0.5, blue: 1.0)
        case .meditate: return Color(red: 0.5, green: 0.9, blue: 0.55)
        case .journal: return Color(red: 0.75, green: 0.55, blue: 1.0)
        case .read: return Color(red: 0.6, green: 0.7, blue: 1.0)
        case .run: return Color(red: 1.0, green: 0.45, blue: 0.35)
        }
    }

    static func matching(title: String) -> PresetTask? {
        allCases.first { $0.title == title }
    }
}
