import DeviceActivity
import ExtensionFoundation
import ExtensionKit
import FamilyControls
import ManagedSettings
import SwiftUI

extension DeviceActivityReport.Context {
    static let totalActivity = Self("Total Activity")
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
        var total: TimeInterval = 0
        var buckets: [String: (name: String, token: ApplicationToken?, duration: TimeInterval)] = [:]

        for await result in data {
            for await segment in result.activitySegments {
                total += segment.totalActivityDuration
                for await category in segment.categories {
                    for await appActivity in category.applications {
                        let app = appActivity.application
                        let key = app.bundleIdentifier
                            ?? app.localizedDisplayName
                            ?? UUID().uuidString
                        let name = app.localizedDisplayName
                            ?? app.bundleIdentifier
                            ?? key
                        let prior = buckets[key]?.duration ?? 0
                        buckets[key] = (
                            name: name,
                            token: app.token,
                            duration: prior + appActivity.totalActivityDuration
                        )
                    }
                }
            }
        }

        let apps = buckets
            .map { AppUsage(id: $0.key, name: $0.value.name, token: $0.value.token, duration: $0.value.duration) }
            .sorted { $0.duration > $1.duration }

        return TotalActivityConfiguration(totalDuration: total, apps: apps)
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
