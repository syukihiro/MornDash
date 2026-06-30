import SwiftUI

struct CelebrationSparkleField: View {
    let seed: Int
    let colors: [Color]
    let active: Bool
    let count: Int

    var body: some View {
        GeometryReader { proxy in
            let size = max(proxy.size.width, proxy.size.height)
            ZStack {
                ForEach(0..<count, id: \.self) { i in
                    CelebrationSparkleParticle(
                        index: i,
                        seed: seed,
                        canvas: size,
                        color: colors[i % colors.count],
                        active: active
                    )
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .ignoresSafeArea()
    }
}

struct CelebrationSparkleParticle: View {
    let index: Int
    let seed: Int
    let canvas: CGFloat
    let color: Color
    let active: Bool

    @State private var animate = false

    var body: some View {
        var rng = CelebrationSeededRandom(seed: UInt64(bitPattern: Int64(seed)) &* 31 &+ UInt64(index) &* 17 &+ 1)
        let angle = rng.next() * 2 * .pi
        let distance = canvas * 0.18 + rng.next() * canvas * 0.32
        let dx = cos(angle) * distance
        let dy = sin(angle) * distance
        let dotSize = 3 + rng.next() * 5
        let delay = rng.next() * 0.5
        let duration = 1.6 + rng.next() * 1.4

        return Circle()
            .fill(color.opacity(0.85))
            .frame(width: dotSize, height: dotSize)
            .shadow(color: color.opacity(0.8), radius: 6)
            .offset(x: animate ? dx : 0, y: animate ? dy : 0)
            .opacity(animate ? 0.0 : 1.0)
            .scaleEffect(animate ? 0.4 : 1.0)
            .onChange(of: active) { _, isActive in
                guard isActive else { return }
                withAnimation(.easeOut(duration: duration).delay(delay)) {
                    animate = true
                }
            }
    }
}

struct CelebrationSeededRandom {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func next() -> Double {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        z = z ^ (z >> 31)
        return Double(z >> 11) / Double(UInt64(1) << 53)
    }
}
