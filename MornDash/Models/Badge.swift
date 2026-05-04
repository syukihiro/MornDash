import SwiftUI

struct Badge: Identifiable, Equatable, Hashable {
    let threshold: Int
    let labelKey: String
    let icon: String
    let color: Color

    var id: Int { threshold }

    static let all: [Badge] = [
        Badge(threshold: 3,   labelKey: "badge_3day",   icon: "sparkles",    color: .mint),
        Badge(threshold: 7,   labelKey: "badge_7day",   icon: "star.fill",   color: .cyan),
        Badge(threshold: 30,  labelKey: "badge_30day",  icon: "trophy.fill", color: .yellow),
        Badge(threshold: 100, labelKey: "badge_100day", icon: "crown.fill",  color: .purple),
    ]

    static let thresholds: [Int] = all.map { $0.threshold }
}
