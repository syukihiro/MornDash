import SwiftUI
import AVFoundation
import Vision

/// カメラプレビューと骨格オーバーレイを同一 UIView 上で描画し、aspectFill のずれを防ぐ。
struct WorkoutCameraPreview: UIViewRepresentable {
    @ObservedObject var cameraManager: CameraManager
    let joints: [VNHumanBodyPoseObservation.JointName: CGPoint]
    var lineColor: UIColor = .white
    var jointColor: UIColor = .white

    func makeUIView(context: Context) -> WorkoutCameraContainerView {
        let view = WorkoutCameraContainerView()
        view.backgroundColor = .black

        let previewLayer = AVCaptureVideoPreviewLayer(session: cameraManager.session)
        previewLayer.videoGravity = .resizeAspectFill
        view.previewLayer = previewLayer
        view.layer.addSublayer(previewLayer)

        let overlay = BodyPoseOverlayView()
        view.overlayView = overlay
        view.addSubview(overlay)

        return view
    }

    func updateUIView(_ uiView: WorkoutCameraContainerView, context: Context) {
        uiView.updateOrientation()
        uiView.overlayView?.update(
            joints: joints,
            previewLayer: uiView.previewLayer,
            lineColor: lineColor,
            jointColor: jointColor
        )
    }
}

final class WorkoutCameraContainerView: UIView {
    var previewLayer: AVCaptureVideoPreviewLayer?
    var overlayView: BodyPoseOverlayView?

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
        overlayView?.frame = bounds
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

final class BodyPoseOverlayView: UIView {
    private var joints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
    private weak var previewLayer: AVCaptureVideoPreviewLayer?
    private var lineColor: UIColor = .white
    private var jointColor: UIColor = .white

    private static let connections: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] = [
        (.nose, .neck),
        (.neck, .leftShoulder),
        (.neck, .rightShoulder),
        (.leftShoulder, .leftElbow),
        (.leftElbow, .leftWrist),
        (.rightShoulder, .rightElbow),
        (.rightElbow, .rightWrist),
        (.leftShoulder, .leftHip),
        (.rightShoulder, .rightHip),
        (.leftHip, .rightHip),
        (.leftHip, .leftKnee),
        (.leftKnee, .leftAnkle),
        (.rightHip, .rightKnee),
        (.rightKnee, .rightAnkle),
    ]

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
        contentMode = .redraw
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(
        joints: [VNHumanBodyPoseObservation.JointName: CGPoint],
        previewLayer: AVCaptureVideoPreviewLayer?,
        lineColor: UIColor,
        jointColor: UIColor
    ) {
        self.joints = joints
        self.previewLayer = previewLayer
        self.lineColor = lineColor
        self.jointColor = jointColor
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(),
              let previewLayer,
              !joints.isEmpty else { return }

        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.setLineWidth(3)
        lineColor.withAlphaComponent(0.9).setStroke()
        jointColor.setFill()

        for (startJoint, endJoint) in Self.connections {
            guard let start = joints[startJoint], let end = joints[endJoint] else { continue }
            let p1 = layerPoint(fromVisionPoint: start, previewLayer: previewLayer)
            let p2 = layerPoint(fromVisionPoint: end, previewLayer: previewLayer)
            context.move(to: p1)
            context.addLine(to: p2)
            context.strokePath()
        }

        for point in joints.values {
            let center = layerPoint(fromVisionPoint: point, previewLayer: previewLayer)
            let dot = CGRect(x: center.x - 5, y: center.y - 5, width: 10, height: 10)
            context.fillEllipse(in: dot)
            lineColor.withAlphaComponent(0.55).setStroke()
            context.setLineWidth(1)
            context.strokeEllipse(in: dot)
        }
    }

    /// Vision 正規化座標（左下原点）→ aspectFill 済みプレビューレイヤー座標
    private func layerPoint(fromVisionPoint point: CGPoint, previewLayer: AVCaptureVideoPreviewLayer) -> CGPoint {
        let metadataRect = CGRect(x: point.x, y: 1.0 - point.y, width: 0, height: 0)
        let layerRect = previewLayer.layerRectConverted(fromMetadataOutputRect: metadataRect)
        return CGPoint(x: layerRect.midX, y: layerRect.midY)
    }
}
