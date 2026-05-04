import SwiftUI

extension View {
    func paywallSheet(isPresented: Binding<Bool>) -> some View {
        self.sheet(isPresented: isPresented) {
            CustomPaywallView()
        }
    }
}
