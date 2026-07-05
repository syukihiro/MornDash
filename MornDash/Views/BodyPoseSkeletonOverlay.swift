import SwiftUI
import Vision

/// waiton 同様、Vision の骨格関節をカメラプレビュー上に描画する。
struct BodyPoseSkeletonOverlay: View {
    let joints: [VNHumanBodyPoseObservation.JointName: CGPoint]
    var lineColor: Color = .white
    var jointColor: Color = .white

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

    var body: some View {
        Canvas { context, size in
            guard !joints.isEmpty else { return }

            for (startJoint, endJoint) in Self.connections {
                guard let start = joints[startJoint], let end = joints[endJoint] else { continue }
                var path = Path()
                path.move(to: mapPoint(start, in: size))
                path.addLine(to: mapPoint(end, in: size))
                context.stroke(
                    path,
                    with: .color(lineColor.opacity(0.9)),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                )
            }

            for point in joints.values {
                let center = mapPoint(point, in: size)
                let dot = CGRect(x: center.x - 5, y: center.y - 5, width: 10, height: 10)
                context.fill(Path(ellipseIn: dot), with: .color(jointColor))
                context.stroke(
                    Path(ellipseIn: dot),
                    with: .color(lineColor.opacity(0.55)),
                    lineWidth: 1
                )
            }
        }
        .allowsHitTesting(false)
    }

    /// Vision 座標（左下原点）→ ミラー済みプレビュー座標（左上原点）
    private func mapPoint(_ point: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(
            x: (1 - point.x) * size.width,
            y: (1 - point.y) * size.height
        )
    }
}
