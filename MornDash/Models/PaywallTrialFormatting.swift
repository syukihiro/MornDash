import Foundation
import RevenueCat

enum PaywallTrialFormatting {
    static func hasFreeTrial(_ package: Package) -> Bool {
        package.storeProduct.introductoryDiscount?.paymentMode == .freeTrial
    }

    static func isAnnualFreeTrial(_ package: Package) -> Bool {
        package.packageType == .annual && hasFreeTrial(package)
    }

    static func periodDescription(for package: Package) -> String? {
        guard let intro = package.storeProduct.introductoryDiscount,
              intro.paymentMode == .freeTrial else { return nil }
        let count = intro.subscriptionPeriod.value * intro.numberOfPeriods
        return localizedPeriod(count: count, unit: intro.subscriptionPeriod.unit)
    }

    static func badgeText(for package: Package) -> String? {
        guard isAnnualFreeTrial(package) else { return nil }
        return NSLocalizedString("paywall_trial_badge_first_week", comment: "")
    }

    static func disclosureText(for package: Package) -> String? {
        guard isAnnualFreeTrial(package) else { return nil }
        let price = package.storeProduct.localizedPriceString
        let period = periodDescription(for: package)
            ?? NSLocalizedString("trial_period_one_week", comment: "")
        return String(
            format: NSLocalizedString("paywall_trial_disclosure_format", comment: ""),
            period,
            price
        )
    }

    private static func localizedPeriod(count: Int, unit: SubscriptionPeriod.Unit) -> String {
        switch unit {
        case .day:
            return String(format: NSLocalizedString("trial_period_days_format", comment: ""), count)
        case .week:
            return String(format: NSLocalizedString("trial_period_weeks_format", comment: ""), count)
        case .month:
            return String(format: NSLocalizedString("trial_period_months_format", comment: ""), count)
        case .year:
            return String(format: NSLocalizedString("trial_period_years_format", comment: ""), count)
        @unknown default:
            return String(format: NSLocalizedString("trial_period_days_format", comment: ""), count)
        }
    }
}
