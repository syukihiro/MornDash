import SwiftUI
import FamilyControls

struct SettingsView: View {
    @ObservedObject var viewModel: HomeViewModel
    @ObservedObject var blockManager: BlockManager
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    @State private var showAppSelection = false
    @State private var showPaywall = false
    @State private var selectionBeforePicker: FamilyActivitySelection?
    @State private var pickerDraft = FamilyActivitySelection()

    var body: some View {
        NavigationStack {
            Form {
                subscriptionSection

                startTimeSection

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
                } footer: {
                    if !subscriptionManager.isPro {
                        Text("settings_categories_pro_only")
                    }
                }
            }
            .navigationTitle(Text("settings_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
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
                NavigationStack {
                    FamilyActivityPicker(selection: $pickerDraft)
                        .navigationTitle(Text("settings_blocked_apps"))
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button(NSLocalizedString("common_done", comment: "")) {
                                    showAppSelection = false
                                }
                            }
                        }
                }
            }
            .paywallSheet(isPresented: $showPaywall)
        }
    }

    // MARK: - Subscription section

    private var subscriptionSection: some View {
        Section {
            subscriptionBanner
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                .listRowSeparator(.hidden)
        } header: {
            Text("settings_subscription_section")
        }
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

    private var proBanner: some View {
        HStack(spacing: 14) {
            Image(systemName: "sunrise.fill")
                .font(.system(size: 26, weight: .ultraLight))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, .yellow],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .shadow(color: .orange.opacity(0.4), radius: 10)
                .frame(width: 44)

            VStack(alignment: .leading, spacing: 3) {
                Text("subscription_pro_title")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                if let plan = subscriptionManager.currentPlan {
                    Text(LocalizedStringKey(plan.displayNameKey))
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.55))
                        .tracking(0.5)
                }
            }

            Spacer(minLength: 0)

            HStack(spacing: 5) {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 6, height: 6)
                Text("subscription_active")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.8)
                    .foregroundColor(.white.opacity(0.85))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule().fill(Color.white.opacity(0.06))
            )
            .overlay(
                Capsule().strokeBorder(Color.orange.opacity(0.25), lineWidth: 1)
            )

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.35))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.orange.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private var upgradeBanner: some View {
        HStack(spacing: 14) {
            Image(systemName: "sunrise.fill")
                .font(.system(size: 26, weight: .ultraLight))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, .yellow],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .shadow(color: .orange.opacity(0.5), radius: 12)
                .frame(width: 44)

            VStack(alignment: .leading, spacing: 3) {
                Text("subscription_pro_title")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text("settings_status_free")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.55))
                    .tracking(0.5)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Text("settings_upgrade_to_pro")
                .font(.system(size: 12, weight: .semibold))
                .tracking(0.3)
                .foregroundColor(.orange)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    Capsule().fill(Color.orange.opacity(0.12))
                )
                .overlay(
                    Capsule().strokeBorder(Color.orange.opacity(0.4), lineWidth: 1)
                )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.orange.opacity(0.25), lineWidth: 1)
                )
        )
    }

    // MARK: - Start time section

    @ViewBuilder
    private var startTimeSection: some View {
        Section {
            weekdayToggleRow
            if viewModel.config.weekdaySchedulingEnabled && subscriptionManager.isPro {
                ForEach(weekdayDisplayOrder, id: \.self) { idx in
                    weekdayPickerRow(idx: idx)
                }
            } else {
                startTimePicker
            }
        } header: {
            Text("settings_start_time")
        }
    }

    @ViewBuilder
    private var weekdayToggleRow: some View {
        if subscriptionManager.isPro {
            Toggle(isOn: weekdaySchedulingBinding) {
                Text("settings_weekday_scheduling")
            }
        } else {
            Button(action: { showPaywall = true }) {
                HStack {
                    Text("settings_weekday_scheduling")
                    Spacer()
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                }
            }
            .foregroundColor(.primary)
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
        HStack {
            Text(Calendar.current.weekdaySymbols[idx])
                .font(.system(size: 15))
            Spacer()
            DatePicker(
                "",
                selection: weekdayTimeBinding(idx: idx),
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()
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

    private var startTimePicker: some View {
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
        .frame(maxWidth: .infinity)
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
