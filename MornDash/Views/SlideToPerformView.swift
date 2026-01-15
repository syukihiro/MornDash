import SwiftUI

struct SlideToPerformView: View {
    let label: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var offset: CGFloat = 0
    private let height: CGFloat = 60
    private let knobSize: CGFloat = 50
    
    var body: some View {
        GeometryReader { geometry in
            let maxDrag = geometry.size.width - height
            
            ZStack(alignment: .leading) {
                // Background Track
                Capsule()
                    .fill(Color.black.opacity(0.3))
                
                Capsule()
                    .stroke(color.opacity(0.3), lineWidth: 1)
                
                // Label
                Text(label)
                    .font(.system(size: 14, weight: .bold))
                    .tracking(2)
                    .foregroundColor(color)
                    .frame(maxWidth: .infinity)
                    .opacity(1.0 - Double(offset / maxDrag))
                
                // Knob
                Circle()
                    .fill(color)
                    .frame(width: knobSize, height: knobSize)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black.opacity(0.8))
                    )
                    .offset(x: 5 + offset) // 5 is padding/margin
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if value.translation.width > 0 && value.translation.width < maxDrag {
                                    offset = value.translation.width
                                }
                            }
                            .onEnded { value in
                                if offset > maxDrag * 0.8 {
                                    // Triggered
                                    withAnimation {
                                        offset = maxDrag
                                    }
                                    // Haptic Feedback
                                    let generator = UIImpactFeedbackGenerator(style: .medium)
                                    generator.impactOccurred()
                                    
                                    // Delay slightly or just call action
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        action()
                                        // Reset
                                        withAnimation {
                                            offset = 0
                                        }
                                    }
                                } else {
                                    // Reset
                                    withAnimation(.spring()) {
                                        offset = 0
                                    }
                                }
                            }
                    )
            }
        }
        .frame(height: 60)
    }
}
