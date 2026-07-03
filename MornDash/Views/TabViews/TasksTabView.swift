import SwiftUI

struct TasksTabView: View {
    @ObservedObject var viewModel: HomeViewModel
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accentTheme) private var accentTheme

    @State private var listEditMode: EditMode = .inactive

    @State private var newTaskTitle: String = ""
    @State private var addTaskTimerEnabled: Bool = false
    @State private var addTaskTimerMinutes: Int = 5
    @State private var addTaskTimerSeconds: Int = 0
    @State private var showAddTaskSheet: Bool = false
    @State private var showRenameTaskSheet: Bool = false
    @State private var renamingTaskID: UUID?
    @State private var renameTaskTitle: String = ""
    @State private var showPresets: Bool = false
    @State private var showPaywall: Bool = false
    @State private var showWorkoutRepPicker: Bool = false
    @State private var workoutRepsDraft: Int = 20
    @State private var workoutRepsInput: String = "20"
    @State private var timerEditingTaskID: UUID?
    @State private var timerEditMinutes: Int = 5
    @State private var timerEditSeconds: Int = 0
    @State private var timerEditSnapshot: (minutes: Int, seconds: Int)?
    @State private var showTimerPicker: Bool = false
    @State private var showFocusDurationPicker: Bool = false
    @State private var focusKindDraft: FocusDetectionKind = .study
    @State private var focusMinutesInput: String = "30"
    @State private var showLastTaskDeleteAlert: Bool = false
    @FocusState private var addTaskSheetFieldFocused: Bool
    @FocusState private var renameTaskSheetFieldFocused: Bool
    @FocusState private var workoutInputFocused: Bool
    @FocusState private var focusMinutesInputFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                MornDashColors.screenBackground(colorScheme).ignoresSafeArea()

                VStack(spacing: 0) {
                    taskList
                    if hasReachedFreeLimit {
                        gateBanner
                    }
                    addTaskButton
                }
            }
            .navigationTitle(Text("tab_tasks"))
            .mornDashNavigationBarStyle()
            .toolbar {
                if !viewModel.taskStore.tasks.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        editModeButton
                    }
                }
            }
            .paywallSheet(isPresented: $showPaywall, source: .tasks)
            .alert("tasks_minimum_one_title", isPresented: $showLastTaskDeleteAlert) {
                Button("common_ok", role: .cancel) {}
            } message: {
                Text("tasks_minimum_one_message")
            }
            .sheet(isPresented: $showAddTaskSheet) {
                addTaskSheet
            }
            .sheet(isPresented: $showRenameTaskSheet) {
                renameTaskSheet
            }
            .sheet(isPresented: $showWorkoutRepPicker) {
                workoutRepPickerSheet
            }
            .sheet(isPresented: $showTimerPicker) {
                timerPickerSheet
            }
            .sheet(isPresented: $showFocusDurationPicker) {
                focusDurationPickerSheet
            }
        }
    }

    private var hasReachedFreeLimit: Bool {
        !subscriptionManager.isPro && viewModel.taskStore.tasks.count >= RevenueCatConfig.freeTaskLimit
    }

    private var hasReachedFreeTimerLimit: Bool {
        !subscriptionManager.isPro && viewModel.taskStore.timerTaskCount >= RevenueCatConfig.freeTimerTaskLimit
    }

    private var gateBanner: some View {
        Button(action: { showPaywall = true }) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .foregroundColor(accentTheme.idleColor)
                Text(String(format: NSLocalizedString("gate_tasks_lock_message", comment: ""), RevenueCatConfig.freeTaskLimit))
                    .font(.caption)
                    .foregroundColor(MornDashColors.labelPrimary(colorScheme, opacity: 0.9))
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(MornDashColors.labelMuted(colorScheme))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(accentTheme.idleColor.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(accentTheme.idleColor.opacity(0.25), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
    }

    private var taskList: some View {
        List {
            Section {
                ForEach(viewModel.taskStore.tasks) { task in
                    HStack(spacing: 14) {
                        Image(systemName: task.isCompletedToday ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 22, weight: .light))
                            .foregroundColor(task.isCompletedToday ? .green : MornDashColors.inactiveIcon(colorScheme))

                        Button(action: { openRenameSheet(for: task) }) {
                            HStack(spacing: 6) {
                                Text(task.title)
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(MornDashColors.labelPrimary(colorScheme))
                                    .multilineTextAlignment(.leading)
                                if !isEditing {
                                    Image(systemName: "pencil")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(accentTheme.idleColor.opacity(0.75))
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .disabled(isEditing)
                        .accessibilityLabel(Text("tasks_rename_accessibility"))
                        .accessibilityValue(task.title)

                        Button(action: { editTimer(for: task) }) {
                            HStack(spacing: 4) {
                                Image(systemName: task.hasTimer ? "timer" : "timer.square")
                                if let timerDurationSeconds = task.timerDurationSeconds {
                                    Text(timerLabel(seconds: timerDurationSeconds))
                                }
                            }
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(task.hasTimer ? accentTheme.blockingColor : MornDashColors.labelTertiary(colorScheme))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(task.hasTimer ? accentTheme.blockingColor.opacity(colorScheme == .dark ? 0.2 : 0.14) : MornDashColors.fieldBackground(colorScheme))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .listRowBackground(MornDashColors.listRowBackground(colorScheme))
                    .listRowSeparatorTint(MornDashColors.listSeparator(colorScheme))
                }
                .onDelete { offsets in
                    if !viewModel.taskStore.remove(at: offsets) {
                        showLastTaskDeleteAlert = true
                    }
                }
            }

            Section {
                Button(action: { withAnimation { showPresets.toggle() } }) {
                    HStack {
                        Text("onboarding_tasks_suggestions")
                            .foregroundColor(MornDashColors.labelPrimary(colorScheme))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(MornDashColors.labelTertiary(colorScheme))
                            .rotationEffect(.degrees(showPresets ? 90 : 0))
                    }
                }
                .buttonStyle(.plain)
                .listRowBackground(MornDashColors.listRowBackground(colorScheme))
                .listRowSeparatorTint(MornDashColors.listSeparator(colorScheme))

                if showPresets {
                    workoutPresetRow
                        .listRowBackground(MornDashColors.listRowBackground(colorScheme))
                        .listRowSeparatorTint(MornDashColors.listSeparator(colorScheme))

                    if UIDevice.current.userInterfaceIdiom != .pad {
                        studyPresetRow
                            .listRowBackground(MornDashColors.listRowBackground(colorScheme))
                            .listRowSeparatorTint(MornDashColors.listSeparator(colorScheme))

                        pcWorkPresetRow
                            .listRowBackground(MornDashColors.listRowBackground(colorScheme))
                            .listRowSeparatorTint(MornDashColors.listSeparator(colorScheme))
                    }

                    ForEach(PresetTask.allCases) { preset in
                        presetRow(preset)
                            .listRowBackground(MornDashColors.listRowBackground(colorScheme))
                            .listRowSeparatorTint(MornDashColors.listSeparator(colorScheme))
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(MornDashColors.screenBackground(colorScheme))
        .environment(\.editMode, $listEditMode)
    }

    private func presetRow(_ preset: PresetTask) -> some View {
        let added = isPresetAdded(preset)
        return Button(action: { togglePreset(preset) }) {
            HStack(spacing: 14) {
                Image(systemName: preset.icon)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(added ? .green : MornDashColors.labelSecondary(colorScheme))
                    .frame(width: 24)
                Text(preset.title)
                    .foregroundColor(MornDashColors.labelPrimary(colorScheme))
                Spacer()
                Image(systemName: added ? "checkmark.circle.fill" : "plus.circle")
                    .font(.system(size: 20))
                    .foregroundColor(added ? .green : MornDashColors.labelTertiary(colorScheme))
            }
        }
        .buttonStyle(.plain)
    }

    private func isPresetAdded(_ preset: PresetTask) -> Bool {
        viewModel.taskStore.tasks.contains { $0.title == preset.title }
    }

    private var workoutPresetRow: some View {
        let title = String(
            format: NSLocalizedString("workout_preset_squats_title", comment: ""),
            workoutRepsDraft
        )
        let added = viewModel.taskStore.tasks.contains { $0.workout == .squat && $0.targetReps == workoutRepsDraft }
        return Button(action: { toggleWorkoutPreset(title: title, added: added) }) {
            HStack(spacing: 14) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(added ? .green : accentTheme.blockingColor)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .foregroundColor(MornDashColors.labelPrimary(colorScheme))
                    Text("workout_preset_ai_badge")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(accentTheme.blockingColor)
                        .tracking(1)
                }
                Spacer()
                if subscriptionManager.isPro {
                    Image(systemName: added ? "checkmark.circle.fill" : "plus.circle")
                        .font(.system(size: 20))
                        .foregroundColor(added ? .green : MornDashColors.labelTertiary(colorScheme))
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14))
                        .foregroundColor(accentTheme.blockingColor)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var studyPresetRow: some View { focusPresetRow(kind: .study) }
    private var pcWorkPresetRow: some View { focusPresetRow(kind: .pcWork) }

    private func focusPresetRow(kind: FocusDetectionKind) -> some View {
        let label = kind == .study
            ? NSLocalizedString("focus_preset_study_label", comment: "")
            : NSLocalizedString("focus_preset_pcwork_label", comment: "")
        let added = viewModel.taskStore.tasks.contains { $0.focusKind == kind }
        return Button(action: { toggleFocusPreset(kind: kind, added: added) }) {
            HStack(spacing: 14) {
                Image(systemName: kind == .study ? "book.fill" : "desktopcomputer")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(added ? .green : accentTheme.blockingColor)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .foregroundColor(MornDashColors.labelPrimary(colorScheme))
                    Text("focus_preset_ai_badge")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(accentTheme.blockingColor)
                        .tracking(1)
                }
                Spacer()
                if subscriptionManager.isPro {
                    Image(systemName: added ? "checkmark.circle.fill" : "plus.circle")
                        .font(.system(size: 20))
                        .foregroundColor(added ? .green : MornDashColors.labelTertiary(colorScheme))
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14))
                        .foregroundColor(accentTheme.blockingColor)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func toggleFocusPreset(kind: FocusDetectionKind, added: Bool) {
        if added {
            viewModel.taskStore.tasks.removeAll { $0.focusKind == kind }
            return
        }
        if !subscriptionManager.isPro {
            showPaywall = true
            return
        }
        if hasReachedFreeLimit { return }
        focusKindDraft = kind
        focusMinutesInput = "30"
        showFocusDurationPicker = true
    }

    private var focusDurationPickerSheet: some View {
        NavigationStack {
            VStack(spacing: 22) {
                let kindLabel = focusKindDraft == .study
                    ? NSLocalizedString("focus_preset_study_label", comment: "")
                    : NSLocalizedString("focus_preset_pcwork_label", comment: "")
                Text(kindLabel)
                    .font(.headline)
                    .foregroundColor(MornDashColors.labelPrimary(colorScheme, opacity: 0.9))

                TextField(NSLocalizedString("tasks_timer_minutes_placeholder", comment: ""), text: $focusMinutesInput)
                    .keyboardType(.numberPad)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusMinutesInputFocused)
                    .padding(14)
                    .foregroundColor(MornDashColors.labelPrimary(colorScheme))
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(MornDashColors.fieldBackground(colorScheme))
                    )
                    .onChange(of: focusMinutesInput) { _, newValue in
                        let filtered = newValue.filter(\.isNumber)
                        if filtered != newValue { focusMinutesInput = filtered }
                    }

                Spacer()

                Button(action: addFocusTask) {
                    Text("workout_reps_picker_add_button")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(Color.white))
                }
                .buttonStyle(.plain)
                .disabled(selectedFocusMinutes == nil)
                .opacity(selectedFocusMinutes == nil ? 0.5 : 1.0)
            }
            .padding(20)
            .mornDashSheetBackground()
            .onAppear { focusMinutesInputFocused = true }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("common_done") { showFocusDurationPicker = false }
                        .foregroundColor(accentTheme.idleColor)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var selectedFocusMinutes: Int? {
        guard let m = Int(focusMinutesInput), (1...180).contains(m) else { return nil }
        return m
    }

    private func addFocusTask() {
        guard let minutes = selectedFocusMinutes else { return }
        let titleKey = focusKindDraft == .study ? "focus_preset_study_title" : "focus_preset_pcwork_title"
        let title = String(format: NSLocalizedString(titleKey, comment: ""), minutes)
        viewModel.taskStore.addFocus(kind: focusKindDraft, targetSeconds: minutes * 60, title: title)
        showFocusDurationPicker = false
    }

    private func toggleWorkoutPreset(title: String, added: Bool) {
        if added {
            viewModel.taskStore.tasks.removeAll { $0.workout == .squat && $0.targetReps == workoutRepsDraft }
            return
        }
        if !subscriptionManager.isPro {
            showPaywall = true
            return
        }
        if hasReachedFreeLimit { return }
        workoutRepsInput = "\(workoutRepsDraft)"
        showWorkoutRepPicker = true
    }

    private var workoutRepPickerSheet: some View {
        NavigationStack {
            VStack(spacing: 22) {
                Text("workout_reps_picker_title")
                    .font(.headline)
                    .foregroundColor(MornDashColors.labelPrimary(colorScheme, opacity: 0.9))

                Text(
                    String(
                        format: NSLocalizedString("workout_preset_squats_title", comment: ""),
                        workoutRepsDraft
                    )
                )
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(MornDashColors.labelPrimary(colorScheme))

                TextField(NSLocalizedString("workout_reps_picker_placeholder", comment: ""), text: $workoutRepsInput)
                    .keyboardType(.numberPad)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($workoutInputFocused)
                    .padding(14)
                    .foregroundColor(MornDashColors.labelPrimary(colorScheme))
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(MornDashColors.fieldBackground(colorScheme))
                    )
                    .onChange(of: workoutRepsInput) { _, newValue in
                        let filtered = newValue.filter(\.isNumber)
                        if filtered != newValue {
                            workoutRepsInput = filtered
                        }
                        if let parsed = Int(filtered), (1...999).contains(parsed) {
                            workoutRepsDraft = parsed
                        }
                    }
                .padding(14)

                if !workoutRepsInput.isEmpty, selectedRepsFromInput == nil {
                    Text("workout_reps_picker_invalid")
                        .font(.footnote)
                        .foregroundColor(.red.opacity(0.9))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer()

                Button(action: addWorkoutTaskWithSelectedReps) {
                    Text("workout_reps_picker_add_button")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(Color.white))
                }
                .buttonStyle(.plain)
                .disabled(selectedRepsFromInput == nil)
                .opacity(selectedRepsFromInput == nil ? 0.5 : 1.0)
            }
            .padding(20)
            .mornDashSheetBackground()
            .onAppear {
                workoutInputFocused = true
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("common_done") {
                        showWorkoutRepPicker = false
                    }
                    .foregroundColor(accentTheme.idleColor)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func addWorkoutTaskWithSelectedReps() {
        guard let reps = selectedRepsFromInput else { return }
        workoutRepsDraft = reps
        let title = String(
            format: NSLocalizedString("workout_preset_squats_title", comment: ""),
            reps
        )
        viewModel.taskStore.addWorkout(.squat, targetReps: reps, title: title)
        showWorkoutRepPicker = false
    }

    private var selectedRepsFromInput: Int? {
        guard let reps = Int(workoutRepsInput), (1...999).contains(reps) else { return nil }
        return reps
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

    private var isEditing: Bool {
        listEditMode == .active
    }

    private var editModeButton: some View {
        Button {
            withAnimation {
                listEditMode = isEditing ? .inactive : .active
            }
        } label: {
            Image(systemName: isEditing ? "checkmark" : "minus.circle")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(accentTheme.idleColor)
        }
        .accessibilityLabel(
            Text(isEditing ? "tasks_edit_done_accessibility" : "tasks_delete_accessibility")
        )
    }

    private var addTaskButton: some View {
        Button(action: openAddTaskSheet) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 34))
                .foregroundColor(accentTheme.idleColor)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .accessibilityLabel(Text("tasks_add_accessibility"))
    }

    private func openAddTaskSheet() {
        if hasReachedFreeLimit {
            showPaywall = true
            return
        }
        resetAddTaskForm()
        showAddTaskSheet = true
    }

    private func resetAddTaskForm() {
        newTaskTitle = ""
        addTaskTimerEnabled = false
        addTaskTimerMinutes = 5
        addTaskTimerSeconds = 0
    }

    private var addTaskSheet: some View {
        NavigationStack {
            VStack(spacing: 18) {
                TextField(
                    NSLocalizedString("settings_add_task_placeholder", comment: ""),
                    text: $newTaskTitle
                )
                .focused($addTaskSheetFieldFocused)
                .submitLabel(.done)
                .onSubmit(addTask)
                .textInputAutocapitalization(.sentences)
                .autocorrectionDisabled()
                .padding(14)
                .foregroundColor(MornDashColors.labelPrimary(colorScheme))
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(MornDashColors.fieldBackground(colorScheme))
                )

                Toggle(isOn: $addTaskTimerEnabled) {
                    Text("tasks_add_timer_toggle")
                        .foregroundColor(MornDashColors.labelPrimary(colorScheme))
                }
                .tint(accentTheme.idleColor)
                .onChange(of: addTaskTimerEnabled) { _, enabled in
                    if enabled {
                        addTaskSheetFieldFocused = false
                        if hasReachedFreeTimerLimit {
                            addTaskTimerEnabled = false
                            showPaywall = true
                        }
                    }
                }

                if addTaskTimerEnabled {
                    TaskTimerWheelPicker(
                        minutes: $addTaskTimerMinutes,
                        seconds: $addTaskTimerSeconds
                    )

                    Text("tasks_timer_sheet_hint")
                        .font(.footnote)
                        .foregroundColor(MornDashColors.labelSecondary(colorScheme))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer(minLength: 0)

                Button(action: addTask) {
                    Text("tasks_add_sheet_title")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(Color.white))
                }
                .buttonStyle(.plain)
                .disabled(!canAdd)
                .opacity(canAdd ? 1.0 : 0.5)
            }
            .padding(20)
            .mornDashSheetBackground()
            .navigationTitle(Text("tasks_add_sheet_title"))
            .navigationBarTitleDisplayMode(.inline)
            .mornDashNavigationBarStyle()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        resetAddTaskForm()
                        showAddTaskSheet = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(accentTheme.idleColor)
                    }
                    .accessibilityLabel(Text("common_cancel"))
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    guard showAddTaskSheet, !addTaskTimerEnabled else { return }
                    addTaskSheetFieldFocused = true
                }
            }
        }
        .presentationDetents(addTaskTimerEnabled ? [.large] : [.medium])
        .presentationDragIndicator(.visible)
    }

    private func openRenameSheet(for task: TaskItem) {
        renamingTaskID = task.id
        renameTaskTitle = task.title
        showRenameTaskSheet = true
    }

    private var renameTaskSheet: some View {
        NavigationStack {
            VStack(spacing: 22) {
                TextField(
                    NSLocalizedString("settings_task_placeholder", comment: ""),
                    text: $renameTaskTitle
                )
                .focused($renameTaskSheetFieldFocused)
                .submitLabel(.done)
                .onSubmit(saveRenamedTask)
                .textInputAutocapitalization(.sentences)
                .autocorrectionDisabled()
                .padding(14)
                .foregroundColor(MornDashColors.labelPrimary(colorScheme))
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(MornDashColors.fieldBackground(colorScheme))
                )

                Spacer()

                Button(action: saveRenamedTask) {
                    Text("common_done")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(Color.white))
                }
                .buttonStyle(.plain)
                .disabled(!canRename)
                .opacity(canRename ? 1.0 : 0.5)
            }
            .padding(20)
            .mornDashSheetBackground()
            .navigationTitle(Text("tasks_rename_sheet_title"))
            .navigationBarTitleDisplayMode(.inline)
            .mornDashNavigationBarStyle()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        closeRenameSheet()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(accentTheme.idleColor)
                    }
                    .accessibilityLabel(Text("common_cancel"))
                }
            }
            .onAppear {
                renameTaskSheetFieldFocused = true
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private var canRename: Bool {
        !renameTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func saveRenamedTask() {
        guard canRename, let renamingTaskID else { return }
        let trimmed = renameTaskTitle.trimmingCharacters(in: .whitespaces)
        guard let index = viewModel.taskStore.tasks.firstIndex(where: { $0.id == renamingTaskID }) else {
            closeRenameSheet()
            return
        }
        viewModel.taskStore.tasks[index].title = trimmed
        closeRenameSheet()
    }

    private func closeRenameSheet() {
        renameTaskTitle = ""
        renamingTaskID = nil
        renameTaskSheetFieldFocused = false
        showRenameTaskSheet = false
    }

    private var canAdd: Bool {
        let hasTitle = !newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty
        guard hasTitle else { return false }
        if addTaskTimerEnabled {
            return selectedAddTaskTimerTotalSeconds != nil
        }
        return true
    }

    private var selectedAddTaskTimerTotalSeconds: Int? {
        TaskTimerFormatters.totalSeconds(minutes: addTaskTimerMinutes, seconds: addTaskTimerSeconds)
    }

    private var selectedEditTimerTotalSeconds: Int? {
        TaskTimerFormatters.totalSeconds(minutes: timerEditMinutes, seconds: timerEditSeconds)
    }

    private func addTask() {
        guard canAdd else { return }
        if hasReachedFreeLimit {
            showPaywall = true
            return
        }

        var timerSeconds: Int?
        if addTaskTimerEnabled {
            guard let total = selectedAddTaskTimerTotalSeconds else { return }
            if hasReachedFreeTimerLimit {
                showPaywall = true
                return
            }
            timerSeconds = total
        }

        viewModel.taskStore.add(newTaskTitle, timerDurationSeconds: timerSeconds)
        addTaskSheetFieldFocused = false
        showAddTaskSheet = false
        resetAddTaskForm()
    }

    private func timerLabel(seconds: Int) -> String {
        TaskTimerFormatters.durationLabel(seconds: seconds)
    }

    private func editTimer(for task: TaskItem) {
        timerEditingTaskID = task.id
        let total = max(task.timerDurationSeconds ?? 300, 1)
        let parts = TaskTimerFormatters.split(seconds: total)
        timerEditMinutes = parts.minutes
        timerEditSeconds = parts.seconds
        timerEditSnapshot = parts
        showTimerPicker = true
    }

    private var timerPickerSheet: some View {
        TaskTimerPickerSheet(
            minutes: $timerEditMinutes,
            seconds: $timerEditSeconds,
            showsRemoveButton: true,
            onRemove: clearTimer,
            onCancel: cancelTimerEdit,
            onDone: saveTimer
        )
    }

    private func cancelTimerEdit() {
        if let timerEditSnapshot {
            timerEditMinutes = timerEditSnapshot.minutes
            timerEditSeconds = timerEditSnapshot.seconds
        }
        showTimerPicker = false
    }

    private func clearTimer() {
        guard let timerEditingTaskID else { return }
        viewModel.taskStore.updateTimer(timerEditingTaskID, timerDurationSeconds: nil)
        showTimerPicker = false
    }

    private func saveTimer() {
        guard let timerEditingTaskID else { return }
        guard let total = selectedEditTimerTotalSeconds else { return }
        let current = viewModel.taskStore.tasks.first(where: { $0.id == timerEditingTaskID })
        let addingNewTimer = current?.hasTimer != true
        if addingNewTimer && hasReachedFreeTimerLimit {
            showPaywall = true
            return
        }
        viewModel.taskStore.updateTimer(timerEditingTaskID, timerDurationSeconds: total)
        showTimerPicker = false
    }
}
