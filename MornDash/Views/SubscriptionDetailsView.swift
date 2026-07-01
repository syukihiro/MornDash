import SwiftUI
import StoreKit

struct SubscriptionDetailsView: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @Environment(\.accentTheme) private var accentTheme
    @State private var showCancelAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                statusHeader
                renewalCard
                managementCard
                cancelCard
                termsCard
            }
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .background(Color.black.ignoresSafeArea())
        .navigationTitle(Text("settings_subscription_section"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .alert(
            Text("subscription_cancel_alert_title"),
            isPresented: $showCancelAlert,
            actions: {
                Button("common_cancel", role: .cancel) {}
                Button("subscription_cancel_alert_proceed", role: .destructive) {
                    openSubscriptionManagement()
                }
            },
            message: {
                Text("subscription_cancel_alert_message")
            }
        )
    }

    // MARK: - Status header

    private var statusHeader: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.05, blue: 0.18),
                    Color(red: 0.18, green: 0.10, blue: 0.04)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: accentTheme.idleGradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                            .shadow(color: accentTheme.idleColor.opacity(0.4), radius: 8, y: 2)
                        Image(systemName: "crown.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("subscription_pro_title")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                        Text(currentPlanLabel)
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    Spacer(minLength: 0)
                }

                Text("subscription_pro_description")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.75))

                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("subscription_active")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.white.opacity(0.12))
                .clipShape(Capsule())
                .overlay(
                    Capsule().strokeBorder(.white.opacity(0.2), lineWidth: 1)
                )
            }
            .padding(20)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(accentTheme.idleColor.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Renewal card

    @ViewBuilder
    private var renewalCard: some View {
        if let expiration = subscriptionManager.proExpirationDate {
            HStack(spacing: 12) {
                Image(systemName: "calendar")
                    .foregroundColor(.white.opacity(0.55))
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text("subscription_next_renewal")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.55))
                    Text(expiration, format: .dateTime.year().month().day())
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                }
                Spacer()
            }
            .padding(16)
            .background(rowBackground)
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Management card

    private var managementCard: some View {
        VStack(spacing: 0) {
            Button(action: openSubscriptionManagement) {
                rowContent(
                    icon: "gearshape",
                    titleKey: "subscription_manage_in_store",
                    showChevron: true
                )
            }
            .buttonStyle(.plain)

            Divider()
                .background(Color.white.opacity(0.08))
                .padding(.leading, 52)
        }
        .background(rowBackground)
        .padding(.horizontal, 16)
    }

    // MARK: - Cancel card

    private var cancelCard: some View {
        Button(action: { showCancelAlert = true }) {
            HStack(spacing: 12) {
                Image(systemName: "xmark.circle")
                    .foregroundColor(.red)
                    .frame(width: 24)
                Text("subscription_cancel")
                    .font(.system(size: 15))
                    .foregroundColor(.red)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.35))
            }
            .padding(16)
            .background(rowBackground)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
    }

    // MARK: - Terms

    private var termsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("subscription_terms_heading")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.85))
                .padding(.bottom, 2)

            Group {
                bulletText("subscription_terms_auto_renew")
                bulletText("subscription_terms_charge")
                bulletText("subscription_terms_manage")
                bulletText("subscription_terms_trial")
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 14) {
                    Link(destination: RevenueCatConfig.termsOfServiceURL) {
                        Text("paywall_terms")
                            .font(.system(size: 11))
                            .foregroundColor(accentTheme.idleColor.opacity(0.8))
                            .underline()
                    }
                    Link(destination: RevenueCatConfig.privacyPolicyURL) {
                        Text("paywall_privacy")
                            .font(.system(size: 11))
                            .foregroundColor(accentTheme.idleColor.opacity(0.8))
                            .underline()
                    }
                }
                Link(destination: RevenueCatConfig.commercialTransactionsURL) {
                    Text("paywall_commercial")
                        .font(.system(size: 11))
                        .foregroundColor(accentTheme.idleColor.opacity(0.8))
                        .underline()
                }
            }
            .padding(.top, 6)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(rowBackground)
        .padding(.horizontal, 16)
    }

    private func bulletText(_ key: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.4))
            Text(key)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.55))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Helpers

    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
            )
    }

    private func rowContent(icon: String, titleKey: LocalizedStringKey, showChevron: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.55))
                .frame(width: 24)
            Text(titleKey)
                .font(.system(size: 15))
                .foregroundColor(.white)
            Spacer()
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.35))
            }
        }
        .padding(16)
    }

    private var currentPlanLabel: LocalizedStringKey {
        if let plan = subscriptionManager.currentPlan {
            return LocalizedStringKey(plan.displayNameKey)
        }
        return "subscription_pro_title"
    }

    private func openSubscriptionManagement() {
        Task { @MainActor in
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                do {
                    try await AppStore.showManageSubscriptions(in: scene)
                    return
                } catch {
                    #if DEBUG
                    print("[SubscriptionDetailsView] showManageSubscriptions failed: \(error)")
                    #endif
                }
            }
            if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                await UIApplication.shared.open(url)
            }
        }
    }
}
