import SwiftUI
import DeviceActivity
import FamilyControls
import ManagedSettings

struct OnboardingView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accentTheme) private var accentTheme
    @Binding var isCompleted: Bool
    @ObservedObject var viewModel: HomeViewModel
    @ObservedObject var blockManager: BlockManager

    @State private var currentStep = 0
    private let stepCount = 7

    var body: some View {
        ZStack {
            LinearGradient(
                colors: MornDashColors.onboardingGradientColors(colorScheme),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal)
                    .padding(.top, 12)

                Group {
                    switch currentStep {
                    case 0:
                        OnboardingProblemView(nextAction: next)
                    case 1:
                        OnboardingHowItWorksView(nextAction: next)
                    case 2:
                        OnboardingPermissionView(nextAction: next)
                    case 3:
                        OnboardingAppsView(blockManager: blockManager, nextAction: next)
                    case 4:
                        OnboardingTimeView(viewModel: viewModel, nextAction: next)
                    case 5:
                        OnboardingTasksView(viewModel: viewModel, nextAction: next)
                    default:
                        OnboardingMotivationView {
                            viewModel.applySchedule(blockManager: blockManager)
                            AnalyticsService.logOnboardingCompleted(
                                blockedAppsCount: blockManager.blockedItemCount,
                                taskCount: viewModel.taskStore.tasks.count,
                                startHour: viewModel.config.startHour,
                                startMinute: viewModel.config.startMinute
                            )
                            withAnimation { isCompleted = true }
                        }
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal)
            }
        }
        .onAppear { AnalyticsService.logOnboardingStepViewed(step: currentStep) }
        .onChange(of: currentStep) { _, step in
            AnalyticsService.logOnboardingStepViewed(step: step)
        }
    }

    private var topBar: some View {
        HStack(spacing: 16) {
            Button(action: back) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(MornDashColors.labelSecondary(colorScheme))
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(MornDashColors.fieldBackground(colorScheme)))
            }
            .opacity(currentStep == 0 ? 0 : 1)
            .disabled(currentStep == 0)

            HStack(spacing: 6) {
                ForEach(0..<stepCount, id: \.self) { index in
                    Capsule()
                        .fill(index <= currentStep ? MornDashColors.onboardingProgressActive(colorScheme, accent: accentTheme) : MornDashColors.onboardingProgressInactive(colorScheme))
                        .frame(height: 4)
                        .frame(maxWidth: .infinity)
                        .animation(.spring(), value: currentStep)
                }
            }

            Color.clear.frame(width: 34, height: 34)
        }
    }

    private func next() {
        withAnimation { currentStep = min(currentStep + 1, stepCount - 1) }
    }

    private func back() {
        withAnimation { currentStep = max(currentStep - 1, 0) }
    }
}

// MARK: - Shared primary button

private struct PrimaryButton: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accentTheme) private var accentTheme
    let title: LocalizedStringKey
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(MornDashColors.onboardingPrimaryButtonText(colorScheme))
                .frame(maxWidth: .infinity)
                .padding()
                .background(Capsule().fill(MornDashColors.onboardingPrimaryButtonFill(colorScheme, enabled: isEnabled, accent: accentTheme)))
        }
        .disabled(!isEnabled)
    }
}

// MARK: - Step 1: Problem

struct OnboardingProblemView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accentTheme) private var accentTheme
    var nextAction: () -> Void
    @State private var appeared = false
    @State private var glowPulse = false

    private let painPoints: [(icon: String, text: LocalizedStringKey)] = [
        ("hand.tap.fill", "onboarding_problem_point_scroll"),
        ("clock.badge.exclamationmark.fill", "onboarding_problem_point_time"),
        ("target", "onboarding_problem_point_mood"),
    ]

    var body: some View {
        ZStack {
            ProblemStormBackdrop(glowPulse: glowPulse)

            VStack(spacing: 0) {
                problemHeroSection
                    .padding(.top, 8)
                    .padding(.bottom, 20)

                VStack(spacing: 12) {
                    ForEach(Array(painPoints.enumerated()), id: \.offset) { index, point in
                        ProblemPainCard(icon: point.icon, text: point.text, index: index)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 24)
                            .animation(
                                .spring(response: 0.55, dampingFraction: 0.78)
                                    .delay(0.12 + Double(index) * 0.1),
                                value: appeared
                            )
                    }
                }

                Spacer(minLength: 16)

                problemContinueButton
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.45), value: appeared)
            }
        }
        .padding(.vertical, 8)
        .onAppear {
            glowPulse = true
            withAnimation(.easeOut(duration: 0.4)) {
                appeared = true
            }
        }
    }

    private var problemHeroSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.purple.opacity(0.5), .pink.opacity(0.2), .clear],
                            center: .center,
                            startRadius: 4,
                            endRadius: 70
                        )
                    )
                    .frame(width: 140, height: 140)
                    .scaleEffect(glowPulse ? 1.08 : 0.92)
                    .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: glowPulse)

                Image(systemName: "iphone.gen3.radiowaves.left.and.right")
                    .font(.system(size: 52, weight: .thin))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [accentTheme.blockingColor, .purple, accentTheme.idleColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .purple.opacity(0.55), radius: 18, y: 4)
            }
            .frame(height: 88)

            VStack(spacing: 10) {
                Text("onboarding_problem_title")
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(
                        LinearGradient(
                            colors: colorScheme == .dark
                                ? [.white, Color(red: 0.85, green: 0.78, blue: 1)]
                                : [MornDashColors.labelPrimary(colorScheme), Color(red: 0.45, green: 0.28, blue: 0.72)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("onboarding_problem_desc")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .foregroundColor(MornDashColors.labelSecondary(colorScheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 4)
        }
    }

    private var problemContinueButton: some View {
        Button(action: nextAction) {
            Text("common_continue")
                .font(.headline.weight(.bold))
                .foregroundColor(MornDashColors.onboardingPrimaryButtonText(colorScheme))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: colorScheme == .dark
                                    ? [.white, Color(red: 0.96, green: 0.94, blue: 1)]
                                    : accentTheme.idleGradientColors,
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .purple.opacity(colorScheme == .dark ? 0.3 : 0.15), radius: 16, y: 6)
                )
        }
        .background(
            Capsule()
                .fill(Color.purple.opacity(0.32))
                .blur(radius: 18)
                .scaleEffect(glowPulse ? 1.04 : 0.96)
                .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: glowPulse)
        )
    }
}

private struct ProblemStormBackdrop: View {
    @Environment(\.colorScheme) private var colorScheme
    let glowPulse: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.purple.opacity(0.2))
                .frame(width: 280, height: 280)
                .blur(radius: 70)
                .offset(y: -120)
                .scaleEffect(glowPulse ? 1.05 : 0.9)
                .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: glowPulse)

            Circle()
                .fill(Color.pink.opacity(0.1))
                .frame(width: 200, height: 200)
                .blur(radius: 50)
                .offset(x: -70, y: 80)
                .scaleEffect(glowPulse ? 0.95 : 1.05)
                .animation(.easeInOut(duration: 5).repeatForever(autoreverses: true), value: glowPulse)
        }
        .allowsHitTesting(false)
    }
}

private struct ProblemPainCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let icon: String
    let text: LocalizedStringKey
    let index: Int

    private var accent: Color {
        switch index {
        case 0: return Color(red: 1, green: 0.5, blue: 0.65)
        case 1: return Color(red: 0.75, green: 0.55, blue: 1)
        default: return Color(red: 0.55, green: 0.65, blue: 1)
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [accent.opacity(0.45), accent.opacity(0.08)],
                            center: .center,
                            startRadius: 2,
                            endRadius: 28
                        )
                    )
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [MornDashColors.iconGradientLeading(colorScheme), accent],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            Text(text)
                .font(.body.weight(.semibold))
                .foregroundColor(MornDashColors.labelPrimary(colorScheme, opacity: 0.92))
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [accent.opacity(0.14), MornDashColors.accentCardGradientEnd(colorScheme)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(
                            LinearGradient(
                                colors: [accent.opacity(0.5), accent.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: accent.opacity(0.15), radius: 12, y: 4)
        .allowsHitTesting(false)
    }
}

// MARK: - Step 2: How it works

struct OnboardingHowItWorksView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accentTheme) private var accentTheme
    var nextAction: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 10)

            VStack(spacing: 12) {
                Text("onboarding_how_title")
                    .font(.title2.bold())
                    .foregroundColor(MornDashColors.labelPrimary(colorScheme))
                Text("onboarding_how_desc")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(MornDashColors.labelSecondary(colorScheme))
            }

            VStack(spacing: 14) {
                HowStepRow(
                    number: "1",
                    icon: "alarm.fill",
                    tint: accentTheme.idleColor,
                    title: "onboarding_how_step1_title",
                    desc: "onboarding_how_step1_desc"
                )
                Connector()
                HowStepRow(
                    number: "2",
                    icon: "lock.fill",
                    tint: accentTheme.blockingColor,
                    title: "onboarding_how_step2_title",
                    desc: "onboarding_how_step2_desc"
                )
                Connector()
                HowStepRow(
                    number: "3",
                    icon: "checkmark.seal.fill",
                    tint: .green,
                    title: "onboarding_how_step3_title",
                    desc: "onboarding_how_step3_desc"
                )
            }
            .padding(.horizontal, 4)

            Spacer()

            PrimaryButton(title: "common_continue", action: nextAction)
        }
        .padding(.vertical, 20)
    }
}

private struct HowStepRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let number: String
    let icon: String
    let tint: Color
    let title: LocalizedStringKey
    let desc: LocalizedStringKey

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.2))
                    .frame(width: 52, height: 52)
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(tint)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(number)
                        .font(.caption.bold())
                        .foregroundColor(MornDashColors.labelTertiary(colorScheme))
                    Text(title)
                        .font(.headline)
                        .foregroundColor(MornDashColors.labelPrimary(colorScheme))
                }
                Text(desc)
                    .font(.footnote)
                    .foregroundColor(MornDashColors.labelSecondary(colorScheme))
            }
            Spacer()
        }
        .padding(14)
        .background(MornDashColors.fieldBackground(colorScheme))
        .cornerRadius(14)
    }
}

private struct Connector: View {
    @Environment(\.colorScheme) private var colorScheme
    var body: some View {
        Rectangle()
            .fill(MornDashColors.hairline(colorScheme))
            .frame(width: 2, height: 14)
            .padding(.leading, 40)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Step 3: Permission

struct OnboardingPermissionView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accentTheme) private var accentTheme
    var nextAction: () -> Void
    @State private var screenTimeAuthorized = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 10)

            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 80))
                .foregroundStyle(LinearGradient(colors: [accentTheme.blockingColor, .purple], startPoint: .bottom, endPoint: .top))
                .shadow(color: accentTheme.blockingColor.opacity(0.5), radius: 20)

            VStack(spacing: 12) {
                Text("onboarding_permission_title")
                    .font(.title2.bold())
                    .foregroundColor(MornDashColors.labelPrimary(colorScheme))

                Text("onboarding_permission_desc")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(MornDashColors.labelSecondary(colorScheme))
            }

            PermissionButton(
                title: NSLocalizedString("onboarding_param_screentime", comment: ""),
                icon: "hourglass",
                isAuthorized: screenTimeAuthorized
            ) {
                await BlockManager().requestAuthorization()
                await MainActor.run { screenTimeAuthorized = true }
            }

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "lock.shield")
                    .font(.footnote)
                    .foregroundColor(MornDashColors.labelTertiary(colorScheme))
                Text("onboarding_permission_note")
                    .font(.footnote)
                    .foregroundColor(MornDashColors.labelTertiary(colorScheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 4)

            Spacer()

            PrimaryButton(title: "common_continue", isEnabled: screenTimeAuthorized, action: {
                AnalyticsService.logOnboardingPermissionGranted()
                nextAction()
            })
        }
        .padding(.vertical, 20)
    }
}

struct PermissionButton: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let icon: String
    let isAuthorized: Bool
    let action: () async -> Void

    var body: some View {
        Button(action: { Task { await action() } }) {
            HStack {
                Image(systemName: icon).font(.title2).frame(width: 30)
                Text(title).font(.headline)
                Spacer()
                Image(systemName: isAuthorized ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isAuthorized ? .green : MornDashColors.inactiveIcon(colorScheme))
            }
            .foregroundColor(MornDashColors.labelPrimary(colorScheme))
            .padding()
            .background(MornDashColors.fieldBackground(colorScheme))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isAuthorized ? Color.green : MornDashColors.inactiveIcon(colorScheme), lineWidth: 1)
            )
        }
        .disabled(isAuthorized)
    }
}

// MARK: - Step 4: Apps

private struct OnboardingUsagePickRow: Identifiable {
    let id: String
    let name: String
    let duration: TimeInterval
    let token: ApplicationToken
}

struct OnboardingAppsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accentTheme) private var accentTheme
    @ObservedObject var blockManager: BlockManager
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @Environment(\.scenePhase) private var scenePhase

    var nextAction: () -> Void
    @State private var showPicker = false
    @State private var showPaywall = false
    @State private var selectionBeforePicker: FamilyActivitySelection?
    @State private var pickerDraft = FamilyActivitySelection()
    @State private var usageRows: [OnboardingUsagePickRow] = []

    private var hasUsageList: Bool {
        #if targetEnvironment(simulator)
        false
        #else
        !usageRows.isEmpty
        #endif
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                #if !targetEnvironment(simulator)
                DeviceActivityReport(.yesterdayUsagePick, filter: yesterdayUnrestrictedFilter)
                    .frame(height: 1)
                    .opacity(0.01)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                #endif

                ScrollView {
                    VStack(spacing: 18) {
                        Text("onboarding_apps_title")
                            .font(.title2.bold())
                            .foregroundColor(MornDashColors.labelPrimary(colorScheme))
                            .frame(maxWidth: .infinity)

                        Text("onboarding_apps_desc")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(MornDashColors.labelSecondary(colorScheme))

                        yesterdayUsageSection

                        Button(action: openAppPicker) {
                            HStack {
                                Text("onboarding_select_apps").font(.headline)
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .foregroundColor(MornDashColors.labelPrimary(colorScheme))
                            .padding()
                            .background(MornDashColors.fieldBackground(colorScheme))
                            .cornerRadius(12)
                        }

                        if selectionCount > 0 {
                            Text(selectionStatusText)
                                .font(.caption)
                                .foregroundColor(.green)
                                .multilineTextAlignment(.center)
                        }

                        if !subscriptionManager.isPro {
                            Text(String(format: NSLocalizedString("onboarding_apps_free_footer", comment: ""), RevenueCatConfig.freeBlockedAppsLimit))
                                .font(.caption2)
                                .foregroundColor(MornDashColors.labelMuted(colorScheme))
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }

            PrimaryButton(title: "common_next", action: nextAction)
                .padding(.top, 8)
        }
        .padding(.vertical, 20)
        .sheet(isPresented: $showPicker, onDismiss: handleAppsPickerDismiss) {
            NavigationStack {
                FamilyActivityPicker(selection: $pickerDraft)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(NSLocalizedString("common_done", comment: "")) { showPicker = false }
                        }
                    }
            }
        }
        .paywallSheet(isPresented: $showPaywall, source: .onboardingApps)
        .onAppear {
            reloadUsageRowsFromCache()
            scheduleUsageCacheReload()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                reloadUsageRowsFromCache()
            }
        }
    }

    private var yesterdayUnrestrictedFilter: DeviceActivityFilter {
        let cal = Calendar.current
        let todayStart = cal.startOfDay(for: Date())
        let yesterdayStart = cal.date(byAdding: .day, value: -1, to: todayStart) ?? todayStart
        return DeviceActivityFilter(
            segment: .daily(during: DateInterval(start: yesterdayStart, end: todayStart)),
            users: .all,
            devices: .init([.iPhone, .iPad]),
            applications: [],
            categories: [],
            webDomains: []
        )
    }

    @ViewBuilder
    private var yesterdayUsageSection: some View {
        #if !targetEnvironment(simulator)
        if hasUsageList {
            VStack(alignment: .leading, spacing: 8) {
                Text("onboarding_apps_yesterday_label")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(MornDashColors.labelTertiary(colorScheme))

                VStack(spacing: 0) {
                    ForEach(usageRows) { row in
                        usageRowView(row)
                    }
                }
                .background(MornDashColors.fieldBackground(colorScheme))
                .cornerRadius(12)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        #endif
    }

    private func usageRowView(_ row: OnboardingUsagePickRow) -> some View {
        let selected = blockManager.selection.applicationTokens.contains(row.token)
        return Button {
            toggleUsageRow(row)
        } label: {
            HStack(spacing: 10) {
                Text(row.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(MornDashColors.labelPrimary(colorScheme, opacity: 0.9))
                    .lineLimit(1)
                Spacer(minLength: 8)
                Text(formattedDuration(row.duration))
                    .font(.caption.weight(.medium).monospacedDigit())
                    .foregroundColor(MornDashColors.labelTertiary(colorScheme))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(selected ? accentTheme.idleColor.opacity(0.85) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private func formattedDuration(_ interval: TimeInterval) -> String {
        let seconds = Int(interval)
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        if h > 0 && m > 0 {
            return String(format: NSLocalizedString("onboarding_usage_hm_format", comment: ""), h, m)
        } else if h > 0 {
            return String(format: NSLocalizedString("onboarding_usage_h_only_format", comment: ""), h)
        } else if seconds >= 60 {
            return String(format: NSLocalizedString("onboarding_usage_m_only_format", comment: ""), m)
        } else if seconds > 0 {
            return NSLocalizedString("onboarding_usage_under_one_m", comment: "")
        }
        return "0m"
    }

    private func reloadUsageRowsFromCache() {
        guard let snapshot = YesterdayUsageCachePayload.loadSnapshot() else {
            usageRows = []
            return
        }
        usageRows = snapshot.rows.compactMap { row in
            guard let sel = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: row.singleAppSelectionData),
                  let token = sel.applicationTokens.first else { return nil }
            let id = "\(row.name)|\(row.durationSeconds)"
            return OnboardingUsagePickRow(id: id, name: row.name, duration: TimeInterval(row.durationSeconds), token: token)
        }
    }

    private func scheduleUsageCacheReload() {
        Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            await MainActor.run { reloadUsageRowsFromCache() }
        }
    }

    private func toggleUsageRow(_ row: OnboardingUsagePickRow) {
        var sel = blockManager.selection
        if sel.applicationTokens.contains(row.token) {
            sel.applicationTokens.remove(row.token)
            blockManager.selection = sel
            return
        }
        if !subscriptionManager.isPro, selectionItemCount(sel) >= RevenueCatConfig.freeBlockedAppsLimit {
            showPaywall = true
            return
        }
        sel.applicationTokens.insert(row.token)
        blockManager.selection = sel
    }

    private var selectionStatusText: String {
        if subscriptionManager.isPro {
            return String(format: NSLocalizedString("onboarding_items_selected", comment: ""), selectionCount)
        }
        return String(
            format: NSLocalizedString("onboarding_items_selected_with_limit", comment: ""),
            selectionCount,
            RevenueCatConfig.freeBlockedAppsLimit
        )
    }

    private func openAppPicker() {
        selectionBeforePicker = blockManager.selection
        pickerDraft = blockManager.selection
        showPicker = true
    }

    private func handleAppsPickerDismiss() {
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

    private var selectionCount: Int {
        blockManager.selection.applicationTokens.count
            + blockManager.selection.categoryTokens.count
            + blockManager.selection.webDomainTokens.count
    }
}

// MARK: - Step 5: Time

struct OnboardingTimeView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accentTheme) private var accentTheme
    @ObservedObject var viewModel: HomeViewModel
    var nextAction: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 10)

            Image(systemName: "sunrise.fill")
                .font(.system(size: 72))
                .foregroundStyle(LinearGradient(colors: accentTheme.idleGradientColors, startPoint: .bottom, endPoint: .top))
                .shadow(color: accentTheme.idleColor.opacity(0.4), radius: 20)

            VStack(spacing: 12) {
                Text("onboarding_time_title")
                    .font(.title2.bold())
                    .foregroundColor(MornDashColors.labelPrimary(colorScheme))

                Text("onboarding_time_desc")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(MornDashColors.labelSecondary(colorScheme))
            }

            DatePicker(
                "",
                selection: Binding(
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
                ),
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .padding()
            .background(MornDashColors.cardFill(colorScheme))
            .cornerRadius(20)

            Spacer()

            PrimaryButton(title: "common_next", action: nextAction)
        }
        .padding(.vertical, 20)
    }
}

// MARK: - Step 6: Tasks

struct OnboardingTasksView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accentTheme) private var accentTheme
    @ObservedObject var viewModel: HomeViewModel
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    var nextAction: () -> Void
    @State private var newTaskTitle = ""
    @State private var showPaywall = false

    private var taskCount: Int { viewModel.taskStore.tasks.count }

    var body: some View {
        VStack(spacing: 10) {
            headerSection

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    suggestionsSection
                    customInputSection
                }
                .padding(.bottom, 8)
            }

            PrimaryButton(
                title: "common_next",
                isEnabled: !viewModel.taskStore.tasks.isEmpty,
                action: nextAction
            )
        }
        .padding(.vertical, 8)
        .paywallSheet(isPresented: $showPaywall, source: .onboardingTasks)
        .onAppear { ensureDefaultStretchSelected() }
    }

    private func ensureDefaultStretchSelected() {
        guard viewModel.taskStore.tasks.isEmpty else { return }
        viewModel.taskStore.add(PresetTask.stretch.title)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("onboarding_tasks_title")
                    .font(.title3.bold())
                    .foregroundColor(MornDashColors.labelPrimary(colorScheme))

                Spacer(minLength: 0)

                if taskCount > 0 {
                    Text(String(format: NSLocalizedString("onboarding_tasks_ritual_count", comment: ""), taskCount))
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Color(red: 0.5, green: 1.0, blue: 0.7))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.green.opacity(0.14)))
                        .transition(.scale.combined(with: .opacity))
                }
            }

            Text("onboarding_tasks_desc")
                .font(.footnote)
                .foregroundColor(MornDashColors.labelTertiary(colorScheme))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: taskCount)
    }

    private var hasReachedFreeLimit: Bool {
        !subscriptionManager.isPro && viewModel.taskStore.tasks.count >= RevenueCatConfig.freeTaskLimit
    }

    private var hasReachedFreeTimerLimit: Bool {
        !subscriptionManager.isPro && viewModel.taskStore.timerTaskCount >= RevenueCatConfig.freeTimerTaskLimit
    }

    private var customOnlyTasks: [TaskItem] {
        viewModel.taskStore.tasks.filter { PresetTask.matching(title: $0.title) == nil }
    }

    private var customInputSection: some View {
        VStack(spacing: 8) {
            OnboardingTasksSectionLabel(
                icon: "pencil.line",
                tint: accentTheme.idleColor,
                title: "onboarding_tasks_custom"
            )

            HStack(spacing: 10) {
                TextField(
                    NSLocalizedString("settings_add_task_placeholder", comment: ""),
                    text: $newTaskTitle
                )
                .foregroundColor(MornDashColors.labelPrimary(colorScheme))
                .textFieldStyle(.plain)
                .submitLabel(.done)
                .onSubmit { addCustomTask() }

                Button(action: addCustomTask) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(
                            newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty ? MornDashColors.inactiveIcon(colorScheme) : MornDashColors.labelPrimary(colorScheme),
                            newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty ? MornDashColors.fieldBackground(colorScheme) : accentTheme.idleColor
                        )
                }
                .disabled(newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(MornDashColors.fieldBackground(colorScheme))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(accentTheme.idleColor.opacity(0.2), lineWidth: 1)
                    )
            )

            if !customOnlyTasks.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(customOnlyTasks) { task in
                            SelectedTaskChip(
                                task: task,
                                preset: nil,
                                onRemove: { removeTask(task.id) }
                            )
                        }
                    }
                }
            }

            if hasReachedFreeLimit {
                Text(String(format: NSLocalizedString("gate_tasks_lock_message", comment: ""), RevenueCatConfig.freeTaskLimit))
                    .font(.caption)
                    .foregroundColor(accentTheme.idleColor.opacity(0.85))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
            }
        }
    }

    private var suggestionsSection: some View {
        VStack(spacing: 8) {
            OnboardingTasksSectionLabel(
                icon: "star.fill",
                tint: .yellow,
                title: "onboarding_tasks_suggestions"
            )

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                ForEach(PresetTask.allCases) { preset in
                    PresetChip(
                        preset: preset,
                        isAdded: isPresetAdded(preset)
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            togglePreset(preset)
                        }
                    }
                }
            }
        }
    }

    private func isPresetAdded(_ preset: PresetTask) -> Bool {
        viewModel.taskStore.tasks.contains { $0.title == preset.title }
    }

    private func togglePreset(_ preset: PresetTask) {
        if let existing = viewModel.taskStore.tasks.first(where: { $0.title == preset.title }) {
            viewModel.taskStore.tasks.removeAll { $0.id == existing.id }
        } else {
            if hasReachedFreeLimit {
                showPaywall = true
                return
            }
            if preset == .meditate {
                if hasReachedFreeTimerLimit {
                    showPaywall = true
                    return
                }
                viewModel.taskStore.tasks.append(
                    TaskItem(title: preset.title, timerDurationSeconds: 5 * 60)
                )
                return
            }
            viewModel.taskStore.add(preset.title)
        }
    }

    private func addCustomTask() {
        let trimmed = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if hasReachedFreeLimit {
            showPaywall = true
            return
        }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            viewModel.taskStore.add(trimmed)
        }
        newTaskTitle = ""
    }

    private func removeTask(_ id: UUID) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            viewModel.taskStore.tasks.removeAll { $0.id == id }
        }
    }
}

private struct OnboardingTasksSectionLabel: View {
    @Environment(\.colorScheme) private var colorScheme
    let icon: String
    let tint: Color
    let title: LocalizedStringKey

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(tint.opacity(0.9))
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .tracking(1.5)
                .foregroundColor(MornDashColors.labelTertiary(colorScheme))
            Spacer()
        }
    }
}

private struct SelectedTaskChip: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accentTheme) private var accentTheme
    let task: TaskItem
    let preset: PresetTask?
    let onRemove: () -> Void

    private var accent: Color { preset?.accentColor ?? accentTheme.blockingColor }

    var body: some View {
        HStack(spacing: 6) {
            if let preset {
                Image(systemName: preset.icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(accent)
            }

            Text(task.title)
                .font(.caption.weight(.medium))
                .foregroundColor(MornDashColors.labelPrimary(colorScheme, opacity: 0.9))
                .lineLimit(1)

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(MornDashColors.labelTertiary(colorScheme), accent.opacity(0.5))
            }
        }
        .padding(.leading, 10)
        .padding(.trailing, 8)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(accent.opacity(0.12))
                .overlay(Capsule().strokeBorder(accent.opacity(0.35), lineWidth: 1))
        )
    }
}

private struct PresetChip: View {
    @Environment(\.colorScheme) private var colorScheme
    let preset: PresetTask
    let isAdded: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        preset.accentColor.opacity(isAdded ? 0.45 : 0.28),
                                        preset.accentColor.opacity(isAdded ? 0.2 : 0.08),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 38, height: 38)

                        Image(systemName: preset.icon)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(isAdded ? MornDashColors.onboardingPrimaryButtonText(colorScheme) : preset.accentColor)
                    }

                    if isAdded {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(MornDashColors.onboardingPrimaryButtonText(colorScheme), preset.accentColor)
                            .offset(x: 5, y: -5)
                            .transition(.scale.combined(with: .opacity))
                    }
                }

                Text(preset.title)
                    .font(.caption2.weight(.medium))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .foregroundColor(isAdded ? MornDashColors.labelPrimary(colorScheme) : MornDashColors.labelPrimary(colorScheme, opacity: 0.85))
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 6)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isAdded ? preset.accentColor.opacity(0.14) : MornDashColors.cardFill(colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(
                        isAdded ? preset.accentColor.opacity(0.55) : MornDashColors.fieldBackground(colorScheme),
                        lineWidth: isAdded ? 1.5 : 1
                    )
            )
            .scaleEffect(isAdded ? 0.97 : 1)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isAdded)
    }
}

// MARK: - Step 7: Motivation

struct OnboardingMotivationView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accentTheme) private var accentTheme
    var finishAction: () -> Void
    @State private var appeared = false
    @State private var sunPulse = false

    private let outcomePoints: [(icon: String, text: LocalizedStringKey)] = [
        ("scope", "onboarding_motivation_point_focus"),
        ("leaf.fill", "onboarding_motivation_point_calm"),
        ("arrow.up.right.circle.fill", "onboarding_motivation_point_self"),
    ]

    var body: some View {
        ZStack {
            MotivationSunriseBackdrop(sunPulse: sunPulse)

            VStack(spacing: 0) {
                heroSection
                    .padding(.top, 8)
                    .padding(.bottom, 20)

                VStack(spacing: 12) {
                    ForEach(Array(outcomePoints.enumerated()), id: \.offset) { index, point in
                        MotivationOutcomeCard(icon: point.icon, text: point.text, index: index)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 24)
                            .animation(
                                .spring(response: 0.55, dampingFraction: 0.78)
                                    .delay(0.12 + Double(index) * 0.1),
                                value: appeared
                            )
                    }
                }

                Spacer(minLength: 16)

                motivationFinishButton
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.45), value: appeared)
            }
        }
        .padding(.vertical, 8)
        .onAppear {
            sunPulse = true
            withAnimation(.easeOut(duration: 0.4)) {
                appeared = true
            }
        }
    }

    private var heroSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [accentTheme.idleColor.opacity(0.55), accentTheme.idleGradientColors.last?.opacity(0.2) ?? accentTheme.idleColor.opacity(0.2), .clear],
                            center: .center,
                            startRadius: 4,
                            endRadius: 70
                        )
                    )
                    .frame(width: 140, height: 140)
                    .scaleEffect(sunPulse ? 1.08 : 0.92)
                    .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: sunPulse)

                Image(systemName: "sun.max.fill")
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: accentTheme.idleGradientColors + [accentTheme.idleColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: accentTheme.idleColor.opacity(0.65), radius: 18, y: 4)
            }
            .frame(height: 88)

            VStack(spacing: 10) {
                Text("onboarding_motivation_title")
                    .font(.system(size: 30, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(
                        LinearGradient(
                            colors: colorScheme == .dark
                                ? [.white, Color(red: 1, green: 0.92, blue: 0.75)]
                                : [MornDashColors.labelPrimary(colorScheme), accentTheme.idleColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("onboarding_motivation_desc")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .foregroundColor(MornDashColors.labelSecondary(colorScheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 4)
        }
    }

    private var motivationFinishButton: some View {
        Button(action: finishAction) {
            Text("onboarding_finish")
                .font(.headline.weight(.bold))
                .foregroundColor(MornDashColors.onboardingPrimaryButtonText(colorScheme))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: colorScheme == .dark
                                    ? [.white, Color(red: 1, green: 0.97, blue: 0.9)]
                                    : accentTheme.idleGradientColors,
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: accentTheme.idleColor.opacity(0.35), radius: 16, y: 6)
                )
        }
        .background(
            Capsule()
                .fill(accentTheme.idleColor.opacity(0.35))
                .blur(radius: 18)
                .scaleEffect(sunPulse ? 1.04 : 0.96)
                .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: sunPulse)
        )
    }
}

private struct MotivationSunriseBackdrop: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accentTheme) private var accentTheme
    let sunPulse: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(accentTheme.idleColor.opacity(0.22))
                .frame(width: 280, height: 280)
                .blur(radius: 70)
                .offset(y: -120)
                .scaleEffect(sunPulse ? 1.05 : 0.9)
                .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: sunPulse)

            Circle()
                .fill(Color.yellow.opacity(0.1))
                .frame(width: 200, height: 200)
                .blur(radius: 50)
                .offset(x: 80, y: 60)
                .scaleEffect(sunPulse ? 0.95 : 1.05)
                .animation(.easeInOut(duration: 5).repeatForever(autoreverses: true), value: sunPulse)
        }
        .allowsHitTesting(false)
    }
}

private struct MotivationOutcomeCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let icon: String
    let text: LocalizedStringKey
    let index: Int

    private var accent: Color {
        switch index {
        case 0: return Color(red: 1, green: 0.75, blue: 0.3)
        case 1: return Color(red: 0.55, green: 0.95, blue: 0.65)
        default: return Color(red: 0.65, green: 0.75, blue: 1)
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [accent.opacity(0.45), accent.opacity(0.08)],
                            center: .center,
                            startRadius: 2,
                            endRadius: 28
                        )
                    )
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [MornDashColors.iconGradientLeading(colorScheme), accent],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            Text(text)
                .font(.body.weight(.semibold))
                .foregroundColor(MornDashColors.labelPrimary(colorScheme, opacity: 0.92))
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [accent.opacity(0.14), MornDashColors.accentCardGradientEnd(colorScheme)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(
                            LinearGradient(
                                colors: [accent.opacity(0.5), accent.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: accent.opacity(0.15), radius: 12, y: 4)
    }
}
