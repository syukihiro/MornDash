import Foundation

enum RevenueCatConfig {
    static let apiKey = "appl_tzljSUrOyTUULhANhGGPbDWdSgG"
    static let proEntitlement = "pro"

    static let weeklyProductID = "pro_weekly_dash"
    static let monthlyProductID = "pro_monthly_dash"
    static let yearlyProductID = "pro_yearly_dash"

    static let freeTaskLimit = 3
    static let freeStatsHistoryDays = 7
    static let freeBlockedAppsLimit = 2

    // TODO: Replace with the project's actual privacy policy URL before App Store submission.
    static let termsOfServiceURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static let privacyPolicyURL = URL(string: "https://www.apple.com/legal/privacy/")!
}
