import SwiftUI
import FamilyControls

struct SettingsView: View {
    @ObservedObject var viewModel: HomeViewModel
    @ObservedObject var blockManager: BlockManager

    @State private var showAppSelection = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    startTimePicker
                } header: {
                    Text("settings_start_time")
                }

                Section {
                    Button(action: { showAppSelection = true }) {
                        HStack {
                            Text("settings_blocked_apps")
                            Spacer()
                            Text("\(selectionCount) \(NSLocalizedString("settings_items_unit", comment: ""))")
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
            .navigationTitle(Text("settings_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onChange(of: viewModel.config.startHour) { _, _ in
                viewModel.applySchedule(blockManager: blockManager)
            }
            .onChange(of: viewModel.config.startMinute) { _, _ in
                viewModel.applySchedule(blockManager: blockManager)
            }
            .sheet(isPresented: $showAppSelection) {
                NavigationStack {
                    FamilyActivityPicker(selection: $blockManager.selection)
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
        }
    }

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
}
