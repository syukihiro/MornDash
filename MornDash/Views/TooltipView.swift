import SwiftUI

struct TooltipView: View {
    let text: String
    let onDismiss: () -> Void
    var arrowDirection: ArrowDirection = .down
    
    enum ArrowDirection {
        case up, down
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if arrowDirection == .up {
                TooltipTriangle()
                    .fill(Color(red: 254/255, green: 44/255, blue: 85/255))
                    .frame(width: 18, height: 9)
            }
            
            HStack(alignment: .top, spacing: 12) {
                Text(text)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 254/255, green: 44/255, blue: 85/255),
                                Color(red: 255/255, green: 0/255, blue: 80/255)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
            )
            .frame(maxWidth: 280)
            
            if arrowDirection == .down {
                TooltipTriangle()
                    .fill(Color(red: 255/255, green: 0/255, blue: 80/255))
                    .frame(width: 18, height: 9)
                    .rotationEffect(.degrees(180))
            }
        }
        .transition(.scale.combined(with: .opacity))
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: true)
    }
}

struct TooltipTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
