import DeviceActivity
import ExtensionFoundation
import ExtensionKit
import FamilyControls
import SwiftUI

struct YesterdayPickReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .yesterdayUsagePick
    let content: (TotalActivityConfiguration) -> YesterdayPickReportChrome

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> TotalActivityConfiguration {
        let full = await AggregatedAppUsage.makeTotalActivityConfiguration(from: data)
        YesterdayUsageCachePayload.save(from: full.apps)
        return TotalActivityConfiguration(totalDuration: 0, apps: [])
    }
}

/// Minimal surface so the system still instantiates the report scene.
struct YesterdayPickReportChrome: View {
    let configuration: TotalActivityConfiguration

    var body: some View {
        Color.clear.frame(width: 4, height: 4)
    }
}
