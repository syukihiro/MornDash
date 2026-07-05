import SwiftUI

struct AmbientBackgroundView: View {
    let color: Color
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accentTheme) private var accentTheme
    @State private var animateOrb = false

    var body: some View {
        ZStack {
            if colorScheme == .dark {
                Color.black
            } else {
                MornDashColors.screenBackgroundGradient(colorScheme)
            }

            Circle()
                .fill(color.opacity(colorScheme == .dark ? 0.3 : 0.22))
                .frame(width: 300, height: 300)
                .blur(radius: colorScheme == .dark ? 60 : 50)
                .offset(x: animateOrb ? -100 : 100, y: animateOrb ? -150 : -50)
                .animation(.easeInOut(duration: 10).repeatForever(autoreverses: true), value: animateOrb)

            Circle()
                .fill(
                    accentTheme.ambientSecondaryColor
                        .opacity(colorScheme == .dark ? 0.2 : 0.16)
                )
                .frame(width: 400, height: 400)
                .blur(radius: colorScheme == .dark ? 80 : 60)
                .offset(x: animateOrb ? 150 : -50, y: animateOrb ? 200 : 100)
                .animation(.easeInOut(duration: 12).repeatForever(autoreverses: true), value: animateOrb)

            if colorScheme == .dark {
                Rectangle()
                    .fill(.white.opacity(0.02))
            }
        }
        .onAppear {
            animateOrb = true
        }
    }
}
