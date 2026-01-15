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
                    VStack(spacing: 12) {
                        // The Massive Time Display
                        Text(viewModel.alarmSettings.time, style: .time)
                            .font(.system(size: 100, weight: .ultraLight, design: .default))
                            .foregroundColor(viewModel.alarmSettings.isEnabled ? .white : .white.opacity(0.3))
                            .shadow(color: viewModel.alarmSettings.isEnabled ? colorForState.opacity(0.8) : .clear, radius: showGlow ? 30 : 10)
                            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: showGlow)
                        
                        if viewModel.alarmSettings.isEnabled {
                            // ナイトスタンドモードの説明
                            Text("Keep app open & screen on")
                                .font(.system(size: 14, weight: .light, design: .rounded))
                                .foregroundColor(.green.opacity(0.8))
                                .tracking(1)
                                .transition(.opacity)
                        } else {
                            Text("READY TO SLEEP?")
                                .font(.caption)
                                .tracking(4)
                                .foregroundColor(.gray)
                                .opacity(0.8)
                        }
                    }
                    .transition(.opacity.combined(with: .scale(scale: 1.1)))
                }
            }
            .frame(height: 300) // Reserve space
            
            Spacer()
            
            // Sound Selector Removed (Moved to Settings)
            
            // Bottom Controls (Minimal)
            if viewModel.appState != .editing {
                VStack(spacing: 30) {
                    // Edit Button
                    Button(action: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            viewModel.appState = .editing
                        }
                    }) {
                        Label("Current Time", systemImage: "pencil")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(.white.opacity(0.05)))
                    }
                    
                    // Slide to Sleep
                    SlideToPerformView(label: "SLIDE TO SLEEP", icon: "moon.stars.fill", color: .indigo.opacity(0.8)) {
                        withAnimation {
                            viewModel.startWindDown(blockManager: blockManager)
                        }
                    }
                    .padding(.horizontal, 40)
                }
                .padding(.bottom, 50)
            }
        }
    }
}
