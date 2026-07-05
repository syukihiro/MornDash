import SwiftUI
import FamilyControls

struct SettingsView: View {
    @ObservedObject var viewModel: HomeViewModel
    @ObservedObject var blockManager: BlockManager
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accentTheme) private var accentTheme

    @AppStorage(AppearanceMode.storageKey) private var appearanceModeRaw = AppearanceMode.dark.rawValue
    @AppStorage(AccentTheme.storageKey) private var accentThemeRaw = AccentTheme.default.rawValue

    @State private var showAppSelection = false
    @State private var showPaywall = false
    @State private var selectionBeforePicker: FamilyActivitySelection?
    @State private var pickerDraft = FamilyActivitySelection()

    var body: some View {
        NavigationStack {
            Form {
                subscriptionSection

                routineSection

                blockingSection

                displaySection

                legalSection
            }
            .mornDashScreenBackground()
            .navigationTitle(Text("settings_title"))
            .navigationBarTitleDisplayMode(.inline)
            .mornDashNavigationBarStyle()
            .onChange(of: viewModel.config.startHour) { _, _ in
                viewModel.applySchedule(blockManager: blockManager)
            }
            .onChange(of: viewModel.config.startMinute) { _, _ in
                viewModel.applySchedule(blockManager: blockManager)
            }
            .onChange(of: viewModel.config.weekdaySchedulingEnabled) { _, _ in
                viewModel.applySchedule(blockManager: blockManager)
            }
            .onChange(of: viewModel.config.weekdayStartTimes) { _, _ in
                viewModel.applySchedule(blockManager: blockManager)
            }
            .sheet(isPresented: $showAppSelection, onDismiss: handleBlockedAppsPickerDismiss) {
                BlockedAppsPickerSheet(
                    selection: $pickerDraft,
                    isPro: subscriptionManager.isPro,
                    appearanceModeRaw: appearanceModeRaw,
                    onUpgrade: { showPaywall = true }
                )
            }
            .paywallSheet(isPresented: $showPaywall, source: .settings)
        }
    }

    // MARK: - Display

    private var displaySection: some View {
        Section {
            Picker(selection: appearanceModeBinding) {
                ForEach(AppearanceMode.allCases) { mode in
                    Text(mode.titleKey).tag(mode)
                }
            } label: {
                Text("settings_appearance")
            }

            if subscriptionManager.isPro {
                colorThemeNavigationRow
            } else {
                proLockRow(titleKey: "settings_color_theme")
            }
        } header: {
            Text("settings_appearance_section")
        }
    }

    private var colorThemeNavigationRow: some View {
        NavigationLink {
            ColorThemePickerView()
                .navigationTitle(Text("settings_color_theme_section"))
                .navigationBarTitleDisplayMode(.inline)
                .mornDashNavigationBarStyle()
        } label: {
            HStack {
                Text("settings_color_theme")
                Spacer()
                Text(selectedAccentTheme.titleKey)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func proLockRow(titleKey: LocalizedStringKey) -> some View {
        Button(action: { showPaywall = true }) {
            HStack {
                Text(titleKey)
                Spacer()
                Text("settings_pro_badge")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(accentTheme.idleColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule().fill(accentTheme.idleColor.opacity(0.12))
                    )
                Image(systemName: "lock.fill")
                    .font(.system(size: 12))
                    .foregroundColor(accentTheme.idleColor)
            }
        }
        .foregroundColor(.primary)
    }

    private var appearanceModeBinding: Binding<AppearanceMode> {
        Binding(
            get: { AppearanceMode(rawValue: appearanceModeRaw) ?? .dark },
            set: { appearanceModeRaw = $0.rawValue }
        )
    }

    private var selectedAccentTheme: AccentTheme {
        AccentTheme(rawValue: accentThemeRaw) ?? .default
    }

    // MARK: - Blocking

    private var blockingSection: some View {
        Section {
            Button(action: openAppPicker) {
                HStack {
                    Text("settings_blocked_apps")
                    Spacer()
                    Text(blockedAppsCountLabel)
                        .foregroundColor(.secondary)
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .foregroundColor(.primary)
        } header: {
            Text("settings_blocking")
        }
    }

    // MARK: - Legal

    private var legalSection: some View {
        Section {
            legalLinkRow(titleKey: "paywall_terms", url: RevenueCatConfig.termsOfServiceURL)
            legalLinkRow(titleKey: "paywall_privacy", url: RevenueCatConfig.privacyPolicyURL)
            legalLinkRow(titleKey: "settings_commercial_transactions", url: RevenueCatConfig.commercialTransactionsURL)
        } header: {
            Text("settings_legal_section")
        }
    }

    private func legalLinkRow(titleKey: LocalizedStringKey, url: URL) -> some View {
        Link(destination: url) {
            HStack {
                Text(titleKey)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .foregroundColor(.primary)
    }

    // MARK: - Subscription

    private var subscriptionSection: some View {
        Section {
            subscriptionBanner
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 10, trailing: 0))
                .listRowSeparator(.hidden)
        }
        .listSectionMargins(.horizontal, 8)
    }

    @ViewBuilder
    private var subscriptionBanner: some View {
        if subscriptionManager.isPro {
            NavigationLink {
                SubscriptionDetailsView()
            } label: {
                proBanner
            }
            .buttonStyle(.plain)
        } else {
            Button(action: { showPaywall = true }) {
                upgradeBanner
            }
            .buttonStyle(.plain)
        }
    }

    private var subscriptionUpgradeGradient: [Color] {
        let colors = accentTheme.idleGradientColors
        if colorScheme == .dark {
            return [
                colors[0].opacity(0.95),
                Color(red: 0.58, green: 0.30, blue: 0.05),
                Color(red: 0.10, green: 0.07, blue: 0.05),
            ]
        }
        return [
            colors[0].opacity(0.34),
            colors[1].opacity(0.24),
            Color(red: 1.0, green: 0.95, blue: 0.88),
        ]
    }

    private var subscriptionProGradient: [Color] {
        if colorScheme == .dark {
            return [
                accentTheme.idleColor.opacity(0.34),
                Color(red: 0.12, green: 0.10, blue: 0.08),
            ]
        }
        return [
            accentTheme.idleColor.opacity(0.18),
            Color(red: 1.0, green: 0.97, blue: 0.93),
        ]
    }

    private var upgradeBannerTitleColor: Color {
        colorScheme == .dark
            ? .white
            : Color(red: 0.20, green: 0.09, blue: 0.02)
    }

    private var upgradeBannerSubtitleColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.9)
            : Color(red: 0.36, green: 0.18, blue: 0.05)
    }

    private var upgradeBanner: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 7) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 15, weight: .semibold))
                    Text("settings_card_free_title")
                        .font(.system(size: 18, weight: .bold))
                }
                .foregroundColor(upgradeBannerTitleColor)

                Text("settings_card_free_subtitle")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(upgradeBannerSubtitleColor)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(upgradeBannerSubtitleColor.opacity(0.85))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: subscriptionUpgradeGradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    if colorScheme == .dark {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.black.opacity(0.12))
                    }
                }
                .shadow(
                    color: accentTheme.idleColor.opacity(colorScheme == .dark ? 0.32 : 0.18),
                    radius: colorScheme == .dark ? 14 : 10,
                    y: 5
                )
        )
    }

    private var proBanner: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text("settings_card_pro_title")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(MornDashColors.labelPrimary(colorScheme))

                if let plan = subscriptionManager.currentPlan {
                    Text(LocalizedStringKey(plan.displayNameKey))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(MornDashColors.labelSecondary(colorScheme))
                } else {
                    Text("settings_card_pro_subtitle")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(MornDashColors.labelSecondary(colorScheme))
                }
            }

            Spacer(minLength: 8)

            HStack(spacing: 5) {
                Circle()
                    .fill(accentTheme.idleColor)
                    .frame(width: 6, height: 6)
                Text("subscription_active")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundColor(colorScheme == .dark ? accentTheme.idleColor : Color(red: 0.45, green: 0.22, blue: 0.04))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule().fill(accentTheme.idleColor.opacity(colorScheme == .dark ? 0.16 : 0.14))
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: subscriptionProGradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(accentTheme.idleColor.opacity(colorScheme == .dark ? 0.32 : 0.24), lineWidth: 1)
                )
        )
    }

    // MARK: - Routine

    @ViewBuilder
    private var routineSection: some View {
        Section {
            if !(viewModel.config.weekdaySchedulingEnabled && subscriptionManager.isPro) {
                startTimeRow
            }

            weekdayToggleRow

            if viewModel.config.weekdaySchedulingEnabled && subscriptionManager.isPro {
                ForEach(weekdayDisplayOrder, id: \.self) { idx in
                    weekdayPickerRow(idx: idx)
                }
            }
        } header: {
            Text("settings_routine_section")
        }
    }

    @ViewBuilder
    private var weekdayToggleRow: some View {
        if subscriptionManager.isPro {
            Toggle(isOn: weekdaySchedulingBinding) {
                Text("settings_weekday_scheduling")
            }
        } else {
            proLockRow(titleKey: "settings_weekday_scheduling")
        }
    }

    private var weekdaySchedulingBinding: Binding<Bool> {
        Binding(
            get: { viewModel.config.weekdaySchedulingEnabled },
            set: { newValue in
                if newValue {
                    let allDefault = viewModel.config.weekdayStartTimes.allSatisfy {
                        $0.hour == 7 && $0.minute == 0
                    }
                    if allDefault {
                        viewModel.config.weekdayStartTimes = Array(
                            repeating: WeekdayTime(
                                hour: viewModel.config.startHour,
                                minute: viewModel.config.startMinute
                            ),
                            count: 7
                        )
                    }
                }
                viewModel.config.weekdaySchedulingEnabled = newValue
            }
        )
    }

    private var weekdayDisplayOrder: [Int] {
        let first = Calendar.current.firstWeekday  // 1=Sun, 2=Mon
        return (0..<7).map { (first - 1 + $0) % 7 }
    }

    private func weekdayPickerRow(idx: Int) -> some View {
        let weekday = Calendar.current.weekdaySymbols[idx]
        let time = weekdayTimeLabel(idx: idx)
        return NavigationLink {
            StartTimePickerView(selection: weekdayTimeBinding(idx: idx))
                .navigationTitle(Text(weekday))
                .navigationBarTitleDisplayMode(.inline)
                .mornDashNavigationBarStyle()
        } label: {
            HStack {
                Text(weekday)
                    .font(.system(size: 15))
                Spacer()
                Text(time)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func weekdayTimeBinding(idx: Int) -> Binding<Date> {
        Binding(
            get: {
                guard idx < viewModel.config.weekdayStartTimes.count else { return Date() }
                let t = viewModel.config.weekdayStartTimes[idx]
                var components = DateComponents()
                components.hour = t.hour
                components.minute = t.minute
                return Calendar.current.date(from: components) ?? Date()
            },
            set: { newValue in
                guard idx < viewModel.config.weekdayStartTimes.count else { return }
                let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                viewModel.config.weekdayStartTimes[idx] = WeekdayTime(
                    hour: components.hour ?? 7,
                    minute: components.minute ?? 0
                )
            }
        )
    }

    // MARK: - Existing rows

    private var startTimeRow: some View {
        NavigationLink {
            StartTimePickerView(selection: startTimeBinding)
                .navigationTitle(Text("settings_start_time_label"))
                .navigationBarTitleDisplayMode(.inline)
                .mornDashNavigationBarStyle()
        } label: {
            HStack {
                Text("settings_start_time_label")
                Spacer()
                Text(startTimeLabel)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var startTimeBinding: Binding<Date> {
        Binding(
            get: {
                var components = DateComponents()
                components.hour = viewModel.config.startHour
                components.minute = viewModel.config.startMinute
                return Calendar.current.date(from: components) ?? Date()
            },
            set: { newValue in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                viewModel.config.startHour = components.hour ?? 7
                viewModel.config.startMinute = components.minute ?? 0
            }
        )
    }

    private var startTimeLabel: String {
        timeLabel(hour: viewModel.config.startHour, minute: viewModel.config.startMinute)
    }

    private func weekdayTimeLabel(idx: Int) -> String {
        guard idx < viewModel.config.weekdayStartTimes.count else { return timeLabel(hour: 7, minute: 0) }
        let t = viewModel.config.weekdayStartTimes[idx]
        return timeLabel(hour: t.hour, minute: t.minute)
    }

    private func timeLabel(hour: Int, minute: Int) -> String {
        String(format: "%02d:%02d", hour, minute)
    }

    private var selectionCount: Int {
        blockManager.selection.applicationTokens.count
            + blockManager.selection.categoryTokens.count
            + blockManager.selection.webDomainTokens.count
    }

    private var blockedAppsCountLabel: String {
        let unit = NSLocalizedString("settings_items_unit", comment: "")
        if subscriptionManager.isPro {
            return "\(selectionCount) \(unit)"
        }
        return "\(selectionCount) / \(RevenueCatConfig.freeBlockedAppsLimit) \(unit)"
    }

    private func openAppPicker() {
        selectionBeforePicker = blockManager.selection
        pickerDraft = blockManager.selection
        showAppSelection = true
    }

    private func handleBlockedAppsPickerDismiss() {
        defer { selectionBeforePicker = nil }
        let hadCategories = !pickerDraft.categoryTokens.isEmpty

        if subscriptionManager.isPro {
            blockManager.selection = pickerDraft
            return
        }

        let sanitized = pickerDraft.clearingCategories()

        if hadCategories, selectionItemCount(sanitized) == 0,
           let prev = selectionBeforePicker, selectionItemCount(prev.clearingCategories()) > 0 {
            blockManager.selection = prev.clearingCategories()
            showPaywall = true
            return
        }

        blockManager.selection = sanitized

        if selectionItemCount(sanitized) > RevenueCatConfig.freeBlockedAppsLimit {
            if let prev = selectionBeforePicker {
                blockManager.selection = prev
            }
            showPaywall = true
            return
        }

        if hadCategories {
            showPaywall = true
        }
    }

    private func selectionItemCount(_ selection: FamilyActivitySelection) -> Int {
        selection.applicationTokens.count + selection.categoryTokens.count + selection.webDomainTokens.count
    }
}

private struct BlockedAppsPickerSheet: View {
    @Binding var selection: FamilyActivitySelection
    let isPro: Bool
    let appearanceModeRaw: String
    let onUpgrade: () -> Void

    @State private var showPicker = false

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accentTheme) private var accentTheme
    @Environment(\.dismiss) private var dismiss

    private var showsPicker: Bool {
        isPro || showPicker
    }

    var body: some View {
        NavigationStack {
            Group {
                if showsPicker {
                    FamilyActivityPicker(selection: $selection)
                } else {
                    BlockedAppsProUpsellScreen(
                        onUpgrade: onUpgrade,
                        onContinue: { showPicker = true }
                    )
                }
            }
            .navigationTitle(Text("settings_blocked_apps"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if showsPicker {
                        Button(NSLocalizedString("common_done", comment: "")) {
                            dismiss()
                        }
                    } else {
                        Button {
                            showPicker = true
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(MornDashColors.labelSecondary(colorScheme))
                                .frame(width: 32, height: 32)
                                .background(Circle().fill(MornDashColors.fieldBackground(colorScheme)))
                        }
                        .accessibilityLabel(Text("settings_blocked_apps"))
                    }
                }
            }
        }
        .preferredColorScheme((AppearanceMode(rawValue: appearanceModeRaw) ?? .dark).preferredColorScheme)
    }
}

private struct BlockedAppsProUpsellScreen: View {
    let onUpgrade: () -> Void
    let onContinue: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accentTheme) private var accentTheme

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                hero

                VStack(spacing: 10) {
                    Text("settings_blocked_apps_pro_upsell_title")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundColor(MornDashColors.labelPrimary(colorScheme))

                    Text("settings_blocked_apps_pro_upsell_subtitle")
                        .font(.system(size: 15, weight: .medium))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .foregroundColor(MornDashColors.labelSecondary(colorScheme))
                }
                .padding(.horizontal, 8)

                VStack(spacing: 0) {
                    upsellFeatureRow(
                        icon: "app.badge.checkmark.fill",
                        textKey: "paywall_feature_unlimited_blocked_apps"
                    )
                    Divider().background(MornDashColors.divider(colorScheme))
                    upsellFeatureRow(
                        icon: "square.grid.2x2.fill",
                        textKey: "settings_blocked_apps_upsell_feature_categories"
                    )
                    Divider().background(MornDashColors.divider(colorScheme))
                    upsellFeatureRow(
                        icon: "globe",
                        textKey: "settings_blocked_apps_upsell_feature_websites"
                    )
                }
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(MornDashColors.cardFill(colorScheme))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(
                                    accentTheme.idleColor.opacity(colorScheme == .dark ? 0.2 : 0.18),
                                    lineWidth: 1
                                )
                        )
                )

                VStack(spacing: 14) {
                    Button(action: onUpgrade) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 14, weight: .semibold))
                            Text("settings_upgrade_to_pro")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(colorScheme == .dark ? .black : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            Capsule().fill(
                                LinearGradient(
                                    colors: accentTheme.idleGradientColors,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        )
                    }
                    .buttonStyle(.plain)

                    Button(action: onContinue) {
                        Text(
                            String(
                                format: NSLocalizedString("settings_blocked_apps_upsell_continue_free", comment: ""),
                                RevenueCatConfig.freeBlockedAppsLimit
                            )
                        )
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(MornDashColors.labelSecondary(colorScheme))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 32)
        }
        .mornDashScreenBackground()
    }

    private var hero: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            accentTheme.idleColor.opacity(colorScheme == .dark ? 0.45 : 0.32),
                            accentTheme.idleColor.opacity(0.05),
                        ],
                        center: .center,
                        startRadius: 8,
                        endRadius: 72
                    )
                )
                .frame(width: 132, height: 132)
                .blur(radius: 4)

            Circle()
                .fill(accentTheme.idleColor.opacity(colorScheme == .dark ? 0.14 : 0.12))
                .frame(width: 96, height: 96)
                .overlay(
                    Circle().strokeBorder(
                        accentTheme.idleColor.opacity(colorScheme == .dark ? 0.35 : 0.28),
                        lineWidth: 1.5
                    )
                )

            Image(systemName: "infinity")
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: accentTheme.idleGradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .padding(.top, 8)
    }

    private func upsellFeatureRow(icon: String, textKey: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(accentTheme.idleColor)
                .frame(width: 24, alignment: .center)
                .padding(.top, 1)

            Text(textKey)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(MornDashColors.labelPrimary(colorScheme))
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
    }
}
