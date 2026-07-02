import SwiftUI

extension View {
    func paywallSheet(isPresented: Binding<Bool>, source: PaywallSource = .other) -> some View {
        self.sheet(isPresented: isPresented) {
            CustomPaywallView(source: source)
        }
    }

    func paywallFullScreenCover(isPresented: Binding<Bool>, source: PaywallSource = .other) -> some View {
        self.fullScreenCover(isPresented: isPresented) {
            CustomPaywallView(source: source)
        }
    }
}
