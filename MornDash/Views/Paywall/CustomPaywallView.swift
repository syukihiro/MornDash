import SwiftUI
import RevenueCat

struct CustomPaywallView: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accentTheme) private var accentTheme

    @State private var selectedPackage: Package?
    @State private var isPurchasing = false
    @State private var errorMessage: PaywallErrorMessage?
    @State private var isRestoring = false

    var body: some View {
        ZStack {
            background
            VStack(spacing: 0) {
                topBar
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        hero
                        featureList
                        plansSection
                        legalLinks
                            .padding(.top, 4)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
                bottomBar
            }
        }
        .task { await loadIfNeeded() }
        .alert(item: $errorMessage) { msg in
            Alert(
                title: Text("paywall_error_title"),
                message: Text(msg.text),
                dismissButton: .default(Text("common_ok"))
            )
        }
    }

    // MARK: - Background

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: MornDashColors.paywallGradientColors(colorScheme),
                startPoint: .top,
                endPoint: .bottom
            )
            RadialGradient(
                colors: [accentTheme.idleColor.opacity(colorScheme == .dark ? 0.18 : 0.22), .clear],
                center: .top,
                startRadius: 0,
                endRadius: 320
            )
        }
        .ignoresSafeArea()
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(MornDashColors.labelSecondary(colorScheme))
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(MornDashColors.fieldBackground(colorScheme)))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(spacing: 12) {
            Image("AppLogo")
                .resizable()
                .scaledToFill()
                .frame(width: 88, height: 88)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [.yellow.opacity(0.55), accentTheme.idleColor.opacity(0.9)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: accentTheme.idleColor.opacity(0.45), radius: 18, y: 2)
                .padding(.top, 8)

            Text("paywall_title")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(MornDashColors.labelPrimary(colorScheme))
                .multilineTextAlignment(.center)

            Text("paywall_subtitle")
                .font(.system(size: 14))
                .foregroundColor(MornDashColors.labelSecondary(colorScheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
        }
    }

    // MARK: - Features

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 14) {
            featureRow(icon: "checklist", text: "paywall_feature_unlimited_tasks")
            featureRow(icon: "apps.iphone", text: "paywall_feature_unlimited_blocked_apps")
            featureRow(icon: "clock.arrow.2.circlepath", text: "paywall_feature_multi_schedule")
            featureRow(icon: "paintpalette.fill", text: "paywall_feature_color_themes")
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(MornDashColors.cardFill(colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(MornDashColors.hairline(colorScheme), lineWidth: 1)
                )
                .mornDashCardShadow(colorScheme)
        )
    }

    private func featureRow(icon: String, text: LocalizedStringKey) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(accentTheme.idleColor)
                .frame(width: 22, height: 22)
                .background(Circle().fill(accentTheme.idleColor.opacity(0.15)))
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(MornDashColors.labelPrimary(colorScheme, opacity: 0.9))
            Spacer(minLength: 0)
        }
    }

    // MARK: - Plans

    @ViewBuilder
    private var plansSection: some View {
        if let offering = subscriptionManager.currentOffering {
            VStack(spacing: 10) {
                ForEach(orderedPackages(for: offering), id: \.identifier) { package in
                    planCard(package: package, weekly: weeklyPackage(in: offering))
                }
            }
        } else if subscriptionManager.isLoadingOfferings {
            ProgressView()
                .tint(accentTheme.idleColor)
                .frame(height: 160)
        } else {
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 24))
                    .foregroundColor(accentTheme.idleColor.opacity(0.7))
                Text("paywall_offerings_unavailable")
                    .font(.system(size: 14))
                    .foregroundColor(MornDashColors.labelSecondary(colorScheme))
                    .multilineTextAlignment(.center)
                Button(action: { Task { await subscriptionManager.loadOfferings(force: true) } }) {
                    Text("paywall_retry")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(accentTheme.idleColor)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(MornDashColors.cardFill(colorScheme))
            )
        }
    }

    private func planCard(package: Package, weekly: Package?) -> some View {
        let isSelected = (selectedPackage?.identifier ?? defaultSelected()?.identifier) == package.identifier
        let isAnnual = package.packageType == .annual
        let savings = savingsPercent(for: package, vs: weekly)

        return Button(action: { selectedPackage = package }) {
            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? accentTheme.idleColor : MornDashColors.hairline(colorScheme), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(accentTheme.idleColor)
                            .frame(width: 12, height: 12)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    if isAnnual || PaywallTrialFormatting.badgeText(for: package) != nil {
                        HStack(spacing: 6) {
                            if isAnnual {
                                planBadge(
                                    text: NSLocalizedString("paywall_badge_best_value", comment: ""),
                                    foreground: .black,
                                    background: AnyShapeStyle(
                                        LinearGradient(
                                            colors: accentTheme.idleGradientColors,
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                )
                            }
                            if let trialBadge = PaywallTrialFormatting.badgeText(for: package) {
                                planBadge(
                                    text: trialBadge,
                                    foreground: accentTheme.idleColor,
                                    background: AnyShapeStyle(accentTheme.idleColor.opacity(0.15))
                                )
                            }
                        }
                    }

                    Text(planTitleKey(for: package))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(MornDashColors.labelPrimary(colorScheme))
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .multilineTextAlignment(.leading)

                    Text(perPeriodLabel(for: package))
                        .font(.system(size: 12))
                        .foregroundColor(MornDashColors.labelTertiary(colorScheme))
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .multilineTextAlignment(.leading)
                }
                .layoutPriority(1)

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 2) {
                    Text(package.storeProduct.localizedPriceString)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(MornDashColors.labelPrimary(colorScheme))
                    if let savings {
                        Text(String(format: NSLocalizedString("paywall_savings_format", comment: ""), savings))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.green)
                    }
                }
                .fixedSize(horizontal: true, vertical: false)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(MornDashColors.paywallPlanFill(colorScheme, selected: isSelected, accent: accentTheme))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                MornDashColors.paywallPlanStroke(colorScheme, selected: isSelected, accent: accentTheme),
                                lineWidth: isSelected ? 1.5 : 1
                            )
                    )
                    .mornDashCardShadow(colorScheme)
            )
        }
        .buttonStyle(.plain)
    }

    private func planBadge(
        text: String,
        foreground: Color,
        background: AnyShapeStyle
    ) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .tracking(0.3)
            .foregroundColor(foreground)
            .lineLimit(2)
            .minimumScaleFactor(0.75)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(background))
    }

    private func planTitleKey(for package: Package) -> LocalizedStringKey {
        switch package.packageType {
        case .weekly: return "paywall_plan_weekly"
        case .monthly: return "paywall_plan_monthly"
        case .annual: return "paywall_plan_annual"
        default: return LocalizedStringKey(package.storeProduct.localizedTitle)
        }
    }

    private func perPeriodLabel(for package: Package) -> String {
        switch package.packageType {
        case .weekly: return NSLocalizedString("paywall_per_week", comment: "")
        case .monthly: return NSLocalizedString("paywall_per_month", comment: "")
        case .annual: return NSLocalizedString("paywall_per_year", comment: "")
        default: return package.storeProduct.localizedDescription
        }
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 12) {
            Button(action: purchase) {
                ZStack {
                    if isPurchasing {
                        ProgressView()
                            .tint(.black)
                    } else {
                        Text(ctaTitle)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.black)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: accentTheme.idleGradientColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
            .disabled(currentSelection() == nil || isPurchasing)
            .opacity(currentSelection() == nil ? 0.4 : 1.0)

            if let pkg = currentSelection(),
               let disclosure = PaywallTrialFormatting.disclosureText(for: pkg) {
                Text(disclosure)
                    .font(.system(size: 10))
                    .foregroundColor(MornDashColors.labelTertiary(colorScheme))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 18) {
                Button(action: restore) {
                    HStack(spacing: 6) {
                        if isRestoring {
                            ProgressView().tint(MornDashColors.labelSecondary(colorScheme))
                        }
                        Text("settings_restore_purchase")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(MornDashColors.labelTertiary(colorScheme))
                    }
                }
                .disabled(isRestoring)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 14)
        .padding(.bottom, 18)
        .background(
            LinearGradient(
                colors: MornDashColors.paywallFooterGradientColors(colorScheme),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
        )
    }

    private var ctaTitle: LocalizedStringKey {
        guard let pkg = currentSelection() else { return "paywall_cta_continue" }
        if PaywallTrialFormatting.isAnnualFreeTrial(pkg) {
            return "paywall_cta_free_trial"
        }
        return "paywall_cta_continue"
    }

    // MARK: - Legal

    private var legalLinks: some View {
        VStack(spacing: 6) {
            HStack(spacing: 14) {
                Link(destination: RevenueCatConfig.termsOfServiceURL) {
                    Text("paywall_terms")
                        .font(.system(size: 11))
                        .foregroundColor(MornDashColors.labelTertiary(colorScheme))
                        .underline()
                }
                Text("·")
                    .font(.system(size: 11))
                    .foregroundColor(MornDashColors.labelMuted(colorScheme))
                Link(destination: RevenueCatConfig.privacyPolicyURL) {
                    Text("paywall_privacy")
                        .font(.system(size: 11))
                        .foregroundColor(MornDashColors.labelTertiary(colorScheme))
                        .underline()
                }
            }
            Link(destination: RevenueCatConfig.commercialTransactionsURL) {
                Text("paywall_commercial")
                    .font(.system(size: 11))
                    .foregroundColor(MornDashColors.labelTertiary(colorScheme))
                    .underline()
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    private func loadIfNeeded() async {
        await subscriptionManager.loadOfferings()
        if selectedPackage == nil {
            selectedPackage = defaultSelected()
        }
    }

    private func defaultSelected() -> Package? {
        guard let offering = subscriptionManager.currentOffering else { return nil }
        let ordered = orderedPackages(for: offering)
        return ordered.first(where: { $0.packageType == .annual }) ?? ordered.first
    }

    private func currentSelection() -> Package? {
        selectedPackage ?? defaultSelected()
    }

    private func orderedPackages(for offering: Offering) -> [Package] {
        let order: [PackageType] = [.annual, .monthly, .weekly]
        let pkgs = offering.availablePackages
        let known = order.compactMap { type in pkgs.first { $0.packageType == type } }
        let extras = pkgs.filter { pkg in !order.contains(pkg.packageType) }
        return known + extras
    }

    private func weeklyPackage(in offering: Offering) -> Package? {
        offering.availablePackages.first { $0.packageType == .weekly }
    }

    private func savingsPercent(for package: Package, vs weekly: Package?) -> Int? {
        guard let weekly else { return nil }
        let weeklyPrice = NSDecimalNumber(decimal: weekly.storeProduct.price).doubleValue
        guard weeklyPrice > 0 else { return nil }
        let pkgPrice = NSDecimalNumber(decimal: package.storeProduct.price).doubleValue

        let pkgPerWeek: Double
        switch package.packageType {
        case .weekly: return nil
        case .monthly: pkgPerWeek = pkgPrice / 4.345
        case .annual: pkgPerWeek = pkgPrice / 52.143
        default: return nil
        }
        let savings = (1.0 - (pkgPerWeek / weeklyPrice)) * 100.0
        guard savings >= 1 else { return nil }
        return Int(savings.rounded())
    }

    // MARK: - Actions

    private func purchase() {
        guard let pkg = currentSelection() else { return }
        isPurchasing = true
        Task {
            defer { isPurchasing = false }
            do {
                let completed = try await subscriptionManager.purchase(pkg)
                if completed, subscriptionManager.isPro {
                    dismiss()
                }
            } catch {
                errorMessage = PaywallErrorMessage(text: error.localizedDescription)
            }
        }
    }

    private func restore() {
        isRestoring = true
        Task {
            defer { isRestoring = false }
            do {
                try await subscriptionManager.restore()
                if subscriptionManager.isPro {
                    dismiss()
                } else {
                    errorMessage = PaywallErrorMessage(
                        text: NSLocalizedString("settings_restore_failure_message", comment: "")
                    )
                }
            } catch {
                errorMessage = PaywallErrorMessage(text: error.localizedDescription)
            }
        }
    }
}

private struct PaywallErrorMessage: Identifiable {
    let id = UUID()
    let text: String
}
