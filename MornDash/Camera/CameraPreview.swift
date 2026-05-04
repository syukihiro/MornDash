import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {
    @ObservedObject var cameraManager: CameraManager

    func makeUIView(context: Context) -> InternalCameraView {
        let view = InternalCameraView()
        view.backgroundColor = .black

        let previewLayer = AVCaptureVideoPreviewLayer(session: cameraManager.session)
        previewLayer.videoGravity = .resizeAspectFill
        view.previewLayer = previewLayer
        view.layer.addSublayer(previewLayer)

        return view
    }

    func updateUIView(_ uiView: InternalCameraView, context: Context) {
        uiView.updateOrientation()
    }
}

final class InternalCameraView: UIView {
    var previewLayer: AVCaptureVideoPreviewLayer?

    override func layoutSubviews() {
        super.layoutSubviews()
        if let layer = previewLayer {
            layer.frame = bounds
        }
    }

    func updateOrientation() {
        guard let connection = previewLayer?.connection else { return }
        if connection.isVideoRotationAngleSupported(90) {
            connection.videoRotationAngle = 90
        }
        if connection.isVideoMirroringSupported {
            connection.automaticallyAdjustsVideoMirroring = false
            connection.isVideoMirrored = true
        }
    }
}
