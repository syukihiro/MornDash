import SwiftUI
import DeviceActivity
import FamilyControls
import ManagedSettings

struct OnboardingView: View {
    @Binding var isCompleted: Bool
    @ObservedObject var viewModel: HomeViewModel
    @ObservedObject var blockManager: BlockManager

    @State private var currentStep = 0
    private let stepCount = 7

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color(red: 0.08, green: 0.08, blue: 0.18)],
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
    }

    private var topBar: some View {
        HStack(spacing: 16) {
            Button(action: back) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.75))
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color.white.opacity(0.08)))
            }
            .opacity(currentStep == 0 ? 0 : 1)
            .disabled(currentStep == 0)

            HStack(spacing: 6) {
                ForEach(0..<stepCount, id: \.self) { index in
                    Capsule()
                        .fill(index <= currentStep ? Color.white : Color.white.opacity(0.18))
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
    let title: LocalizedStringKey
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Capsule().fill(isEnabled ? Color.white : Color.white.opacity(0.3)))
        }
        .disabled(!isEnabled)
    }
}

private struct SectionHeader: View {
    let title: LocalizedStringKey

    var body: some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold))
            .tracking(2)
            .foregroundColor(.white.opacity(0.55))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Step 1: Problem

struct OnboardingProblemView: View {
    var nextAction: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 10)

            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.purple.opacity(0.35), .clear], startPoint: .top, endPoint: .bottom))
                    .frame(width: 200, height: 200)
                    .blur(radius: 40)

                Image(systemName: "iphone.gen3.radiowaves.left.and.right")
                    .font(.system(size: 90, weight: .thin))
                    .foregroundStyle(LinearGradient(colors: [.indigo, .purple], startPoint: .top, endPoint: .bottom))
                    .shadow(color: .purple.opacity(0.6), radius: 20)
            }

            VStack(spacing: 14) {
                Text("onboarding_problem_title")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)

                Text("onboarding_problem_desc")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 8)

            VStack(spacing: 10) {
                ProblemRow(icon: "hand.tap.fill", text: "onboarding_problem_point_scroll")
                ProblemRow(icon: "clock.badge.exclamationmark.fill", text: "onboarding_problem_point_time")
                ProblemRow(icon: "target", text: "onboarding_problem_point_mood")
            }

            Spacer()

            PrimaryButton(title: "common_continue", action: nextAction)
        }
        .padding(.vertical, 20)
    }
}

private struct ProblemRow: View {
    let icon: String
    let text: LocalizedStringKey

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.pink.opacity(0.85))
                .frame(width: 28)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.85))
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.06))
        .cornerRadius(12)
    }
}

// MARK: - Step 2: How it works

struct OnboardingHowItWorksView: View {
    var nextAction: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 10)

            VStack(spacing: 12) {
                Text("onboarding_how_title")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                Text("onboarding_how_desc")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.7))
            }

            VStack(spacing: 14) {
                HowStepRow(
                    number: "1",
                    icon: "alarm.fill",
                    tint: .orange,
                    title: "onboarding_how_step1_title",
                    desc: "onboarding_how_step1_desc"
                )
                Connector()
                HowStepRow(
                    number: "2",
                    icon: "lock.fill",
                    tint: .indigo,
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
                        .foregroundColor(.white.opacity(0.5))
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                }
                Text(desc)
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.7))
            }
            Spacer()
        }
        .padding(14)
        .background(Color.white.opacity(0.06))
        .cornerRadius(14)
    }
}

private struct Connector: View {
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.2))
            .frame(width: 2, height: 14)
            .padding(.leading, 40)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Step 3: Permission

struct OnboardingPermissionView: View {
    var nextAction: () -> Void
    @State private var screenTimeAuthorized = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 10)

            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 80))
                .foregroundStyle(LinearGradient(colors: [.indigo, .purple], startPoint: .bottom, endPoint: .top))
                .shadow(color: .indigo.opacity(0.5), radius: 20)

            VStack(spacing: 12) {
                Text("onboarding_permission_title")
                    .font(.title2.bold())
                    .foregroundColor(.white)

                Text("onboarding_permission_desc")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.75))
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
                    .foregroundColor(.white.opacity(0.5))
                Text("onboarding_permission_note")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.5))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 4)

            Spacer()

            PrimaryButton(title: "common_continue", isEnabled: screenTimeAuthorized, action: nextAction)
        }
        .padding(.vertical, 20)
    }
}

struct PermissionButton: View {
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
                    .foregroundColor(isAuthorized ? .green : .white.opacity(0.3))
            }
            .foregroundColor(.white)
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isAuthorized ? Color.green : Color.white.opacity(0.3), lineWidth: 1)
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
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)

                        Text("onboarding_apps_desc")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white.opacity(0.65))

                        yesterdayUsageSection

                        Button(action: openAppPicker) {
                            HStack {
                                Text("onboarding_select_apps").font(.headline)
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.white.opacity(0.1))
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
                                .foregroundColor(.white.opacity(0.42))
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
        .paywallSheet(isPresented: $showPaywall)
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
                    .foregroundColor(.white.opacity(0.5))

                VStack(spacing: 0) {
                    ForEach(usageRows) { row in
                        usageRowView(row)
                    }
                }
                .background(Color.white.opacity(0.06))
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
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(1)
                Spacer(minLength: 8)
                Text(formattedDuration(row.duration))
                    .font(.caption.weight(.medium).monospacedDigit())
                    .foregroundColor(.white.opacity(0.45))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(selected ? Color.orange.opacity(0.85) : Color.clear, lineWidth: 2)
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
    @ObservedObject var viewModel: HomeViewModel
    var nextAction: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 10)

            Image(systemName: "sunrise.fill")
                .font(.system(size: 72))
                .foregroundStyle(LinearGradient(colors: [.orange, .yellow], startPoint: .bottom, endPoint: .top))
                .shadow(color: .orange.opacity(0.4), radius: 20)

            VStack(spacing: 12) {
                Text("onboarding_time_title")
                    .font(.title2.bold())
                    .foregroundColor(.white)

                Text("onboarding_time_desc")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.75))
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
            .colorScheme(.dark)
            .labelsHidden()
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(20)

            Spacer()

            PrimaryButton(title: "common_next", action: nextAction)
        }
        .padding(.vertical, 20)
    }
}

// MARK: - Step 6: Tasks

struct OnboardingTasksView: View {
    @ObservedObject var viewModel: HomeViewModel
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    var nextAction: () -> Void
    @State private var newTaskTitle = ""
    @State private var showPaywall = false

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Text("onboarding_tasks_title")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                Text("onboarding_tasks_desc")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.75))
            }
            .padding(.top, 8)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    yourTasksSection
                    customInputSection
                    suggestionsSection
                }
                .padding(.bottom, 12)
            }

            PrimaryButton(
                title: "common_next",
                isEnabled: !viewModel.taskStore.tasks.isEmpty,
                action: nextAction
            )
        }
        .padding(.vertical, 16)
        .paywallSheet(isPresented: $showPaywall)
    }

    private var hasReachedFreeLimit: Bool {
        !subscriptionManager.isPro && viewModel.taskStore.tasks.count >= RevenueCatConfig.freeTaskLimit
    }

    private var hasReachedFreeTimerLimit: Bool {
        !subscriptionManager.isPro && viewModel.taskStore.timerTaskCount >= RevenueCatConfig.freeTimerTaskLimit
    }

    private var yourTasksSection: some View {
        VStack(spacing: 8) {
            SectionHeader(title: "onboarding_tasks_your_list")

            if viewModel.taskStore.tasks.isEmpty {
                Text("onboarding_tasks_empty")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(10)
            } else {
                VStack(spacing: 6) {
                    ForEach(viewModel.taskStore.tasks) { task in
                        HStack {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 6))
                                .foregroundColor(.white.opacity(0.35))
                            Text(task.title)
                                .foregroundColor(.white)
                                .font(.subheadline)
                            Spacer()
                            Button(action: { removeTask(task.id) }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red.opacity(0.7))
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(10)
                    }
                }
            }
        }
    }

    private var customInputSection: some View {
        VStack(spacing: 8) {
            SectionHeader(title: "onboarding_tasks_custom")

            HStack {
                TextField(
                    NSLocalizedString("settings_add_task_placeholder", comment: ""),
                    text: $newTaskTitle
                )
                .foregroundColor(.white)
                .textFieldStyle(.plain)
                .submitLabel(.done)
                .onSubmit { addCustomTask() }

                Button(action: addCustomTask) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty ? .white.opacity(0.3) : .green)
                }
                .disabled(newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.08))
            .cornerRadius(10)

            if hasReachedFreeLimit {
                Text(String(format: NSLocalizedString("gate_tasks_lock_message", comment: ""), RevenueCatConfig.freeTaskLimit))
                    .font(.caption)
                    .foregroundColor(.orange.opacity(0.85))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
            }
        }
    }

    private var suggestionsSection: some View {
        VStack(spacing: 8) {
            SectionHeader(title: "onboarding_tasks_suggestions")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(PresetTask.allCases) { preset in
                    PresetChip(
                        preset: preset,
                        isAdded: isPresetAdded(preset)
                    ) {
                        togglePreset(preset)
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
        viewModel.taskStore.add(trimmed)
        newTaskTitle = ""
    }

    private func removeTask(_ id: UUID) {
        viewModel.taskStore.tasks.removeAll { $0.id == id }
    }
}

private struct PresetChip: View {
    let preset: PresetTask
    let isAdded: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: preset.icon)
                    .font(.system(size: 14))
                    .foregroundColor(isAdded ? .green : .white.opacity(0.7))
                    .frame(width: 18)
                Text(preset.title)
                    .font(.footnote)
                    .lineLimit(1)
                    .foregroundColor(.white)
                Spacer(minLength: 0)
                Image(systemName: isAdded ? "checkmark.circle.fill" : "plus.circle")
                    .font(.footnote)
                    .foregroundColor(isAdded ? .green : .white.opacity(0.5))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .background(Color.white.opacity(isAdded ? 0.14 : 0.06))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isAdded ? Color.green.opacity(0.6) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Step 7: Motivation

struct OnboardingMotivationView: View {
    var finishAction: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 10)

            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.orange.opacity(0.5), .clear], startPoint: .top, endPoint: .bottom))
                    .frame(width: 220, height: 220)
                    .blur(radius: 50)

                Image(systemName: "sun.max.fill")
                    .font(.system(size: 90, weight: .light))
                    .foregroundStyle(LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom))
                    .shadow(color: .orange.opacity(0.6), radius: 24)
            }

            VStack(spacing: 14) {
                Text("onboarding_motivation_title")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)

                Text("onboarding_motivation_desc")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.75))
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 10) {
                MotivationRow(icon: "scope", text: "onboarding_motivation_point_focus")
                MotivationRow(icon: "leaf.fill", text: "onboarding_motivation_point_calm")
                MotivationRow(icon: "arrow.up.right.circle.fill", text: "onboarding_motivation_point_self")
            }

            Spacer()

            PrimaryButton(title: "onboarding_finish", action: finishAction)
        }
        .padding(.vertical, 20)
    }
}

private struct MotivationRow: View {
    let icon: String
    let text: LocalizedStringKey

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.yellow.opacity(0.9))
                .frame(width: 28)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.06))
        .cornerRadius(12)
    }
}
