import SwiftUI

struct CameraPermissionDeniedView: View {
    @Environment(\.accentTheme) private var accentTheme

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.fill")
                .font(.system(size: 44))
                .foregroundColor(.white.opacity(0.35))
            Text("camera_permission_denied_title")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
            Text("camera_permission_denied_message")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.65))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button(action: CameraManager.openSettings) {
                Text("camera_open_settings")
                    .font(.system(size: 15, weight: .semibold))
            }
            .buttonStyle(.borderedProminent)
            .tint(accentTheme.blockingColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}
