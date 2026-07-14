import Foundation
import FirebaseAnalytics
import StoreKit

/// Centralized Firebase Analytics events for funnel and revenue tracking.
enum AnalyticsService {

    /// `false` on Simulator and TestFlight so those sessions never pollute production metrics.
    /// Resolved asynchronously in `configureCollection()`; stays `false` until then.
    private(set) static var isCollectionEnabled = false

    private static var configurationTask: Task<Void, Never>?

    /// Call once after `FirebaseApp.configure()`. Disables automatic + manual collection when not production.
    static func configureCollection() {
        #if targetEnvironment(simulator) || DEBUG
        applyCollectionEnabled(false)
        #else
        configurationTask = Task {
            applyCollectionEnabled(await isProductionEnvironment())
        }
        #endif
    }

    /// 環境判定の完了を待つ。`isCollectionEnabled` を判定後に参照したい呼び出し元用。
    static func waitUntilConfigured() async {
        await configurationTask?.value
    }

    private static func applyCollectionEnabled(_ enabled: Bool) {
        isCollectionEnabled = enabled
        Analytics.setAnalyticsCollectionEnabled(enabled)
        #if DEBUG
        print("[Analytics] collection enabled: \(enabled)")
        #endif
    }

    #if !targetEnvironment(simulator) && !DEBUG
    /// App Store 本番インストールなら true。TestFlight は `.sandbox`、Xcode 直インストールは `.xcode`。
    /// 環境を取得できなかった場合は従来挙動(sandboxReceipt なし=本番)に合わせて true。
    /// (App Store / TestFlight 経由なら署名済み AppTransaction が端末内に必ずあるため、失敗は実質起きない)
    private static func isProductionEnvironment() async -> Bool {
        guard let result = try? await AppTransaction.shared else { return true }
        switch result {
        case .verified(let transaction), .unverified(let transaction, _):
            return transaction.environment == .production
        }
    }
    #endif

    // MARK: - Onboarding

    static func logOnboardingStepViewed(step: Int) {
        log("onboarding_step_view", ["step": step])
    }

    static func logOnboardingPermissionGranted() {
        log("onboarding_permission_granted")
    }

    static func logOnboardingCompleted(
        blockedAppsCount: Int,
        taskCount: Int,
        startHour: Int,
        startMinute: Int
    ) {
        log("onboarding_completed", [
            "blocked_apps_count": blockedAppsCount,
            "task_count": taskCount,
            "start_hour": startHour,
            "start_minute": startMinute,
        ])
    }

    // MARK: - Paywall

    static func logPaywallShown(source: PaywallSource) {
        log("paywall_shown", ["source": source.rawValue])
    }

    static func logPaywallDismissed(source: PaywallSource) {
        log("paywall_dismissed", ["source": source.rawValue])
    }

    static func logPaywallPurchaseTapped(source: PaywallSource, plan: String) {
        log("paywall_purchase_tapped", [
            "source": source.rawValue,
            "plan": plan,
        ])
    }

    static func logPaywallPurchaseSuccess(source: PaywallSource, plan: String) {
        log("paywall_purchase_success", [
            "source": source.rawValue,
            "plan": plan,
        ])
    }

    static func logPaywallPurchaseFailed(source: PaywallSource, plan: String) {
        log("paywall_purchase_failed", [
            "source": source.rawValue,
            "plan": plan,
        ])
    }

    static func logPaywallRestoreTapped(source: PaywallSource) {
        log("paywall_restore_tapped", ["source": source.rawValue])
    }

    static func logPaywallRestoreSuccess(source: PaywallSource) {
        log("paywall_restore_success", ["source": source.rawValue])
    }

    // MARK: - Retention

    static func logRoutineCompleted(streak: Int, isFirstEver: Bool) {
        log("routine_completed", [
            "streak": streak,
            "is_first_ever": isFirstEver ? 1 : 0,
        ])
    }

    static func logGiveUp(streak: Int) {
        log("give_up", ["streak": streak])
    }

    /// ストリーク節目で App Store 評価リクエストを表示したとき(YouTrainy と同じイベント名)。
    static func logReviewRequested(milestone: Int) {
        log("app_store_review_requested", ["milestone": milestone])
    }

    // MARK: - User properties

    static func setIsPro(_ isPro: Bool) {
        guard isCollectionEnabled else { return }
        Analytics.setUserProperty(isPro ? "true" : "false", forName: "is_pro")
    }

    // MARK: - Private

    private static func log(_ name: String, _ params: [String: Any] = [:]) {
        #if DEBUG
        print("[Analytics] \(name) \(params)")
        #endif
        guard isCollectionEnabled else { return }
        Analytics.logEvent(name, parameters: params.isEmpty ? nil : params)
    }
}

enum PaywallSource: String {
    case onboarding
    case onboardingApps = "onboarding_apps"
    case onboardingTasks = "onboarding_tasks"
    case tasks
    case settings
    case stats
    case other
}
