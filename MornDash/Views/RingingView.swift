import SwiftUI
import FamilyControls

struct RingingView: View {
    @ObservedObject var viewModel: HomeViewModel
    @ObservedObject var blockManager: BlockManager
    let showGlow: Bool
    
    var body: some View {
        VStack {
            Spacer()
            
            ZStack {
                // Pulse Effect
                Circle()
                    .stroke(Color.red.opacity(0.5), lineWidth: 2)
                    .frame(width: 200, height: 200)
                    .scaleEffect(showGlow ? 1.5 : 0.8)
                    .opacity(showGlow ? 0 : 1)
                    .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: showGlow)
                
                Image(systemName: "alarm.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.white)
                    .shadow(color: .red, radius: 20)
                    .symbolEffect(.wiggle.clockwise, options: .repeating)
            }
            
            Spacer()
            
            VStack(spacing: 20) {
                Button(action: {
                    viewModel.snoozeAlarm()
                }) {
                    Text("ringing_snooze")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                SlideToPerformView(label: NSLocalizedString("ringing_slide_to_stop", comment: ""), icon: "alarm.fill", color: .red) {
                    withAnimation {
                        viewModel.stopAlarmAndStartBlock(blockManager: blockManager)
                    }
                }
                .padding(.horizontal, 40)
            }
            .padding(.bottom, 40)
        }
    }
}
