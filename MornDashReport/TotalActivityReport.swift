import DeviceActivity
import ExtensionFoundation
import ExtensionKit
import FamilyControls
import ManagedSettings
import SwiftUI

extension DeviceActivityReport.Context {
    static let totalActivity = Self("Total Activity")
    /// Same raw value must be used in the main app host (`DeviceActivityReport`).
    static let yesterdayUsagePick = Self("Yesterday Usage Pick")
}

struct AppUsage: Identifiable {
    let id: String
    let name: String
    let token: ApplicationToken?
    let duration: TimeInterval
}

struct TotalActivityConfiguration {
    let totalDuration: TimeInterval
    let apps: [AppUsage]
}

struct TotalActivityReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .totalActivity
    let content: (TotalActivityConfiguration) -> TotalActivityView

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> TotalActivityConfiguration {
        await AggregatedAppUsage.makeTotalActivityConfiguration(from: data)
    }

    static func formatted(_ interval: TimeInterval) -> String {
        let seconds = Int(interval)
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        if h > 0 && m > 0 {
            return "\(h)h \(m)m"
        } else if h > 0 {
            return "\(h)h"
        } else if seconds >= 60 {
            return "\(m)m"
        } else if seconds > 0 {
            return "<1m"
        } else {
            return "0m"
        }
    }
}
