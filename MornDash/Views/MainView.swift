import SwiftUI
import FamilyControls

struct MainView: View {
    @ObservedObject var viewModel: HomeViewModel
    @ObservedObject var blockManager: BlockManager
    let colorForState: Color
    let showGlow: Bool

    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Central Element: TIME or EDITOR
            ZStack {
                if viewModel.appState == .editing {
                    // 編集モード: DatePicker表示
                    VStack(spacing: 20) {
                        DatePicker("", selection: $viewModel.alarmSettings.time, displayedComponents: .hourAndMinute)
                            .datePickerStyle(WheelDatePickerStyle())
                            .labelsHidden()
                            .colorScheme(.dark)
                            .frame(width: 300, height: 200)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.ultraThinMaterial)
                            )
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                viewModel.appState = .standby
                            }
                        }) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 30, weight: .light))
                                .foregroundColor(.white)
                                .padding(20)
                                .background(Circle().fill(.white.opacity(0.1)))
                        }
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                } else {
                    // 通常モード: 時刻表示（タップで編集）
                    VStack(spacing: 20) {
                        // The Massive Time Display (タップで編集)
                        Text(viewModel.alarmSettings.time, style: .time)
                            .font(.system(size: 100, weight: .ultraLight, design: .default))
                            .foregroundColor(viewModel.alarmSettings.isEnabled ? .white : .white.opacity(0.3))
                            .shadow(color: viewModel.alarmSettings.isEnabled ? colorForState.opacity(0.8) : .clear, radius: showGlow ? 30 : 10)
                            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: showGlow)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    viewModel.appState = .editing
                                }
                            }
                        
                        // Status Text
                        if viewModel.alarmSettings.isEnabled {
                            Text("main_alarm_on")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.green.opacity(0.9))
                                .tracking(2)
                        } else {
                            Text("main_alarm_off")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.gray.opacity(0.7))
                                .tracking(2)
                        }
                    }
                    .transition(.opacity.combined(with: .scale(scale: 1.1)))
                }
            }
            .frame(height: 300) // Reserve space
            
            Spacer()
            
            // Simple ON/OFF Toggle Button (編集モード時は非表示)
            if viewModel.appState != .editing {
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        viewModel.toggleAlarm()
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: viewModel.alarmSettings.isEnabled ? "bell.fill" : "bell.slash.fill")
                            .font(.system(size: 24, weight: .medium))
                        
                        Text(viewModel.alarmSettings.isEnabled ? "main_turn_off" : "main_turn_on")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 18)
                    .background(
                        Capsule()
                            .fill(viewModel.alarmSettings.isEnabled ? Color.red.opacity(0.7) : Color.green.opacity(0.7))
                            .shadow(color: (viewModel.alarmSettings.isEnabled ? Color.red : Color.green).opacity(0.4), radius: 15, x: 0, y: 5)
                    )
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.alarmSettings.isEnabled)
                .padding(.bottom, 80)
            }
        }
    }
}
