import SwiftUI

struct TaskTimerWheelPicker: View {
    @Binding var minutes: Int
    @Binding var seconds: Int
    @Environment(\.colorScheme) private var colorScheme

    private let minuteRange = 0...TaskTimerFormatters.maxMinutes

    var body: some View {
        HStack(spacing: 0) {
            wheelColumn(selection: $minutes, values: Array(minuteRange), label: { "\($0)" })
            unitLabel("tasks_timer_minutes_label")
            wheelColumn(
                selection: $seconds,
                values: Array(secondsRange),
                label: { String(format: "%02d", $0) }
            )
            unitLabel("tasks_timer_seconds_label")
        }
        .frame(height: 196)
        .onChange(of: minutes) { _, newMinutes in
            if newMinutes >= TaskTimerFormatters.maxMinutes, seconds > 0 {
                seconds = 0
            }
        }
    }

    private var secondsRange: ClosedRange<Int> {
        minutes >= TaskTimerFormatters.maxMinutes ? 0...0 : 0...59
    }

    private func wheelColumn<Value: Hashable>(
        selection: Binding<Value>,
        values: [Value],
        label: @escaping (Value) -> String
    ) -> some View {
        Picker("", selection: selection) {
            ForEach(values, id: \.self) { value in
                Text(label(value)).tag(value)
            }
        }
        .pickerStyle(.wheel)
        .frame(maxWidth: .infinity)
        .clipped()
        .labelsHidden()
    }

    private func unitLabel(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(.body.weight(.semibold))
            .foregroundColor(MornDashColors.labelSecondary(colorScheme))
            .frame(width: 28)
    }
}

struct TaskTimerPickerSheet: View {
    @Binding var minutes: Int
    @Binding var seconds: Int
    var showsRemoveButton: Bool = false
    var onRemove: (() -> Void)?
    var onCancel: (() -> Void)?
    let onDone: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accentTheme) private var accentTheme

    private var isValid: Bool {
        TaskTimerFormatters.totalSeconds(minutes: minutes, seconds: seconds) != nil
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                TaskTimerWheelPicker(minutes: $minutes, seconds: $seconds)

                Text("tasks_timer_sheet_hint")
                    .font(.footnote)
                    .foregroundColor(MornDashColors.labelTertiary(colorScheme))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)

                if showsRemoveButton, let onRemove {
                    Button(action: onRemove) {
                        Text("tasks_timer_remove")
                            .font(.headline)
                            .foregroundColor(MornDashColors.labelPrimary(colorScheme))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Capsule().fill(MornDashColors.fieldBackground(colorScheme)))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 20)
            .mornDashSheetBackground()
            .navigationTitle(Text("tasks_timer_sheet_title"))
            .navigationBarTitleDisplayMode(.inline)
            .mornDashNavigationBarStyle()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        if let onCancel {
                            onCancel()
                        } else {
                            onDone()
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(accentTheme.idleColor)
                    }
                    .accessibilityLabel(Text("common_cancel"))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("common_done", action: onDone)
                        .fontWeight(.semibold)
                        .foregroundColor(accentTheme.idleColor)
                        .disabled(!isValid)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
