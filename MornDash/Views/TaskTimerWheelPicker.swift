import SwiftUI

struct TaskTimerWheelPicker: View {
    @Binding var minutes: Int
    @Binding var seconds: Int

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
            .foregroundColor(.white.opacity(0.65))
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

    private var isValid: Bool {
        TaskTimerFormatters.totalSeconds(minutes: minutes, seconds: seconds) != nil
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                TaskTimerWheelPicker(minutes: $minutes, seconds: $seconds)

                Text("tasks_timer_sheet_hint")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)

                if showsRemoveButton, let onRemove {
                    Button(action: onRemove) {
                        Text("tasks_timer_remove")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Capsule().fill(Color.white.opacity(0.12)))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 20)
            .background(Color.black.ignoresSafeArea())
            .navigationTitle(Text("tasks_timer_sheet_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
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
                            .foregroundColor(.orange)
                    }
                    .accessibilityLabel(Text("common_cancel"))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("common_done", action: onDone)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                        .disabled(!isValid)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
    }
}
