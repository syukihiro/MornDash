import DeviceActivity
import ExtensionFoundation
import ExtensionKit
import SwiftUI

@main
struct MornDashReportExtension: DeviceActivityReportExtension {
    @MainActor
    var body: some DeviceActivityReportScene {
        TotalActivityReport { configuration in
            TotalActivityView(configuration: configuration)
        }
        YesterdayPickReport { configuration in
            YesterdayPickReportChrome(configuration: configuration)
        }
    }
}
