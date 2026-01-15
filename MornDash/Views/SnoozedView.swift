import SwiftUI

struct SnoozedView: View {
    @ObservedObject var viewModel: HomeViewModel
    let showGlow: Bool
    
    var body: some View {
        VStack {
            Spacer()
            
            Text("zZ")
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
            
            Button("Dismiss") {
                viewModel.appState = .standby
            }
            .foregroundColor(.white.opacity(0.5))
            .padding(.bottom, 50)
        }
    }
}
