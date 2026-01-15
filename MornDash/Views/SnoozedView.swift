import SwiftUI
import FamilyControls

struct SnoozedView: View {
    @ObservedObject var viewModel: HomeViewModel
    @ObservedObject var blockManager: BlockManager
    let showGlow: Bool
    
    var body: some View {
        VStack {
            Spacer()
            
            Text("snoozed_zzz")
                .font(.system(size: 120, weight: .ultraLight))
                .foregroundColor(.white.opacity(0.3))
                .offset(x: showGlow ? 10 : -10, y: showGlow ? -20 : 0)
                .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: showGlow)
            
            let min = viewModel.remainingSnoozeTime / 60
            let sec = viewModel.remainingSnoozeTime % 60
            Text(String(format: "%02d:%02d", min, sec))
                .font(.system(size: 30, design: .monospaced))
                .foregroundColor(.orange)
                .tracking(2)
                .padding(.top)
                
            Spacer()
            
            SlideToPerformView(label: NSLocalizedString("ringing_slide_to_stop", comment: ""), icon: "alarm.fill", color: .orange) {
                withAnimation {
                    viewModel.stopAlarmAndStartBlock(blockManager: blockManager)
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
        }
    }
}
