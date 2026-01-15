import SwiftUI

struct WindDownView: View {
    @ObservedObject var viewModel: HomeViewModel
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Text("WIND DOWN")
                .font(.caption)
                .tracking(8)
                .foregroundColor(.indigo.opacity(0.8))
            
            VStack(spacing: 10) {
                Text("CURRENT TIME")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.3))
                    .tracking(2)
                
                Text(viewModel.currentTime, style: .time)
                    .font(.system(size: 60, weight: .thin))
                    .foregroundColor(.white)
            }
            
            Divider()
                .frame(width: 50)
                .background(Color.white.opacity(0.2))
            
            VStack(spacing: 10) {
                Text(viewModel.alarmSettings.time, style: .time)
                    .font(.system(size: 80, weight: .ultraLight))
                    .foregroundColor(.green.opacity(0.8))
                    .shadow(color: .green.opacity(0.3), radius: 10)
                
                Text("WAKE UP TIME")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.3))
                    .tracking(2)
            }
            
            Spacer()
            
            Spacer()
            
            // 停止スライダー
            SlideToPerformView(label: "SLIDE TO STOP", icon: "xmark", color: .white.opacity(0.3)) {
                withAnimation {
                    viewModel.cancelWindDown()
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
}
