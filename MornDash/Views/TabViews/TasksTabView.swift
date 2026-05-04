import SwiftUI

struct TasksTabView: View {
    @ObservedObject var viewModel: HomeViewModel
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    @State private var newTaskTitle: String = ""
    @State private var showPresets: Bool = false
    @State private var showPaywall: Bool = false
    @FocusState private var addFieldFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    taskList
                    if hasReachedFreeLimit {
                        gateBanner
                    }
                    addBar
                }
            }
            .navigationTitle(Text("tab_tasks"))
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                if !viewModel.taskStore.tasks.isEmpty {
                    EditButton()
                        .foregroundColor(.orange)
                }
            }
            .paywallSheet(isPresented: $showPaywall)
        }
    }

    private var hasReachedFreeLimit: Bool {
        !subscriptionManager.isPro && viewModel.taskStore.tasks.count >= RevenueCatConfig.freeTaskLimit
    }

    private var gateBanner: some View {
        Button(action: { showPaywall = true }) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .foregroundColor(.orange)
                Text(String(format: NSLocalizedString("gate_tasks_lock_message", comment: ""), RevenueCatConfig.freeTaskLimit))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.orange.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.orange.opacity(0.25), lineWidth: 1)
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
                ForEach($viewModel.taskStore.tasks) { $task in
                    HStack(spacing: 14) {
                        Image(systemName: task.isCompletedToday ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 22, weight: .light))
                            .foregroundColor(task.isCompletedToday ? .green : .white.opacity(0.35))
                        TextField(
                            NSLocalizedString("settings_task_placeholder", comment: ""),
                            text: $task.title
                        )
                        .foregroundColor(.white)
                    }
                    .listRowBackground(Color.white.opacity(0.04))
                    .listRowSeparatorTint(.white.opacity(0.08))
                }
                .onDelete { offsets in
                    viewModel.taskStore.remove(at: offsets)
                }
            } footer: {
                Text("settings_tasks_footer")
                    .foregroundColor(.white.opacity(0.5))
            }

            Section {
                Button(action: { withAnimation { showPresets.toggle() } }) {
                    HStack {
                        Text("onboarding_tasks_suggestions")
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.5))
                            .rotationEffect(.degrees(showPresets ? 90 : 0))
                    }
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.white.opacity(0.04))
                .listRowSeparatorTint(.white.opacity(0.08))

                if showPresets {
                    ForEach(PresetTask.allCases) { preset in
                        presetRow(preset)
                            .listRowBackground(Color.white.opacity(0.04))
                            .listRowSeparatorTint(.white.opacity(0.08))
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.black)
    }

    private func presetRow(_ preset: PresetTask) -> some View {
        let added = isPresetAdded(preset)
        return Button(action: { togglePreset(preset) }) {
            HStack(spacing: 14) {
                Image(systemName: preset.icon)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(added ? .green : .white.opacity(0.7))
                    .frame(width: 24)
                Text(preset.title)
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: added ? "checkmark.circle.fill" : "plus.circle")
                    .font(.system(size: 20))
                    .foregroundColor(added ? .green : .white.opacity(0.5))
            }
        }
        .buttonStyle(.plain)
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
            viewModel.taskStore.add(preset.title)
        }
    }

    private var addBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "plus")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))

            TextField(
                NSLocalizedString("settings_add_task_placeholder", comment: ""),
                text: $newTaskTitle
            )
            .focused($addFieldFocused)
            .submitLabel(.done)
            .onSubmit(addTask)
            .foregroundColor(.white)

            Button(action: addTask) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 26))
                    .foregroundColor(canAdd ? .orange : .white.opacity(0.2))
            }
            .disabled(!canAdd)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.06))
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    private var canAdd: Bool {
        !newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func addTask() {
        guard canAdd else { return }
        if hasReachedFreeLimit {
            showPaywall = true
            return
        }
        viewModel.taskStore.add(newTaskTitle)
        newTaskTitle = ""
        addFieldFocused = false
    }
}
