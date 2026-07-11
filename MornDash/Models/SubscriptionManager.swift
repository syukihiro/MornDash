import Combine
import FirebaseAnalytics
import Foundation
import RevenueCat

@MainActor
final class SubscriptionManager: NSObject, ObservableObject {
    static let shared = SubscriptionManager()

    @Published private(set) var isPro: Bool = false
    @Published private(set) var customerInfo: CustomerInfo?
    @Published private(set) var currentOffering: Offering?
    @Published private(set) var isLoadingOfferings: Bool = false
    @Published private(set) var offeringsError: String?

    private var configured = false

    func configure() {
        guard !configured else { return }
        configured = true

        #if DEBUG
        Purchases.logLevel = .debug
        #else
        Purchases.logLevel = .info
        #endif

        Purchases.configure(withAPIKey: RevenueCatConfig.apiKey)
        Purchases.shared.delegate = self
        syncFirebaseAttribution()

        Task { await refresh() }
    }

    /// Links this device to Firebase Analytics so RevenueCat can forward purchase lifecycle events.
    func syncFirebaseAttribution() {
        guard AnalyticsService.isCollectionEnabled else { return }
        guard let appInstanceID = Analytics.appInstanceID() else {
            #if DEBUG
            print("[SubscriptionManager] Firebase app instance ID not yet available")
            #endif
            return
        }
        Purchases.shared.attribution.setFirebaseAppInstanceID(appInstanceID)
    }

    func refresh() async {
        do {
            let info = try await Purchases.shared.customerInfo()
            apply(info)
        } catch {
            #if DEBUG
            print("[SubscriptionManager] customerInfo fetch failed: \(error)")
            #endif
        }
    }

    func restore() async throws {
        let info = try await Purchases.shared.restorePurchases()
        apply(info)
    }

    func loadOfferings(force: Bool = false) async {
        if !force, currentOffering != nil { return }
        isLoadingOfferings = true
        offeringsError = nil
        do {
            let offerings = try await Purchases.shared.offerings()
            currentOffering = offerings.current
            if currentOffering == nil {
                offeringsError = "no_current_offering"
            }
        } catch {
            offeringsError = error.localizedDescription
            #if DEBUG
            print("[SubscriptionManager] offerings fetch failed: \(error)")
            #endif
        }
        isLoadingOfferings = false
    }

    /// Returns true if the purchase completed, false if the user cancelled.
    func purchase(_ package: Package) async throws -> Bool {
        let result = try await Purchases.shared.purchase(package: package)
        apply(result.customerInfo)
        return !result.userCancelled
    }

    private func apply(_ info: CustomerInfo) {
        customerInfo = info
        isPro = info.entitlements[RevenueCatConfig.proEntitlement]?.isActive == true
        AnalyticsService.setIsPro(isPro)
    }

    var proExpirationDate: Date? {
        customerInfo?.entitlements[RevenueCatConfig.proEntitlement]?.expirationDate
    }

    var currentProductIdentifier: String? {
        customerInfo?.entitlements[RevenueCatConfig.proEntitlement]?.productIdentifier
    }

    var currentPlan: ProPlan? {
        ProPlan(productIdentifier: currentProductIdentifier)
    }

    enum ProPlan {
        case weekly
        case monthly
        case yearly

        init?(productIdentifier: String?) {
            switch productIdentifier {
            case RevenueCatConfig.weeklyProductID: self = .weekly
            case RevenueCatConfig.monthlyProductID: self = .monthly
            case RevenueCatConfig.yearlyProductID: self = .yearly
            default: return nil
            }
        }

        var displayNameKey: String {
            switch self {
            case .weekly: return "paywall_plan_weekly"
            case .monthly: return "paywall_plan_monthly"
            case .yearly: return "paywall_plan_annual"
            }
        }
    }
}

extension SubscriptionManager: PurchasesDelegate {
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            self.apply(customerInfo)
        }
    }
}
