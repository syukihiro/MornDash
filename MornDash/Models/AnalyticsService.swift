import Foundation
import FirebaseAnalytics

/// Centralized Firebase Analytics events for funnel and revenue tracking.
enum AnalyticsService {

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

    // MARK: - User properties

    static func setIsPro(_ isPro: Bool) {
        Analytics.setUserProperty(isPro ? "true" : "false", forName: "is_pro")
    }

    // MARK: - Private

    private static func log(_ name: String, _ params: [String: Any] = [:]) {
        #if DEBUG
        print("[Analytics] \(name) \(params)")
        #endif
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
