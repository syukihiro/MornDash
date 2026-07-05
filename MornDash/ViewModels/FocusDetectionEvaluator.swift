import Vision
import CoreGraphics

struct FocusEvaluation {
    enum Reason { case ok, noFace, multipleFaces, lowQuality, badAngle, faceTooSmall }
    let isFocused: Bool
    let reason: Reason
}

struct FocusDetectionEvaluator: Sendable {
    var minFaceAreaRatio: CGFloat = 0.05

    nonisolated func evaluate(observations: [VNFaceObservation], kind _: FocusDetectionKind) -> FocusEvaluation {
        if observations.count == 0 {
            return FocusEvaluation(isFocused: false, reason: .noFace)
        }
        if observations.count >= 2 {
            return FocusEvaluation(isFocused: false, reason: .multipleFaces)
        }

        let face = observations[0]
        let area = face.boundingBox.width * face.boundingBox.height
        if area < minFaceAreaRatio {
            return FocusEvaluation(isFocused: false, reason: .faceTooSmall)
        }

        return FocusEvaluation(isFocused: true, reason: .ok)
    }
}
