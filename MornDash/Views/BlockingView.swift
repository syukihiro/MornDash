import SwiftUI
import FamilyControls

struct BlockingView: View {
    @ObservedObject var viewModel: HomeViewModel
    
    var body: some View {
        VStack {
            Spacer()
            
            Image(systemName: "lock")
                .font(.system(size: 60, weight: .ultraLight))
                .foregroundColor(.white.opacity(0.5))
                .padding(.bottom, 20)
            
            Text("\(viewModel.remainingBlockTime)")
                .font(.system(size: 140, weight: .thin, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .indigo.opacity(0.8), radius: 30)
                
            Text("blocking_focus")
                .font(.caption)
                .tracking(10)
                .foregroundColor(.indigo)
                
            Spacer()
        }
    }
}
