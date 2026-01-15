import SwiftUI

struct AmbientBackgroundView: View {
    let color: Color
    @State private var animateOrb = false
    
    var body: some View {
        ZStack {
            Color.black
            
            // Orb 1
            Circle()
                .fill(color.opacity(0.3))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .offset(x: animateOrb ? -100 : 100, y: animateOrb ? -150 : -50)
                .animation(.easeInOut(duration: 10).repeatForever(autoreverses: true), value: animateOrb)
            
            // Orb 2
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 400, height: 400)
                .blur(radius: 80)
                .offset(x: animateOrb ? 150 : -50, y: animateOrb ? 200 : 100)
                .animation(.easeInOut(duration: 12).repeatForever(autoreverses: true), value: animateOrb)
                
            // Grain Overlay (Optional texture)
            Rectangle()
                .fill(.white.opacity(0.02))
        }
        .onAppear {
            animateOrb = true
        }
    }
}
