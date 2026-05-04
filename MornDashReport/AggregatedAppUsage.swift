import DeviceActivity
import ExtensionFoundation
import ExtensionKit
import FamilyControls
import ManagedSettings
import SwiftUI

enum AggregatedAppUsage {
    /// Shared aggregation for stats and onboarding usage pick list.
    static func makeTotalActivityConfiguration(from data: DeviceActivityResults<DeviceActivityData>) async -> TotalActivityConfiguration {
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
}
