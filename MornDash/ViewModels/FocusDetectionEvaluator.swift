import Vision
import CoreGraphics

struct FocusEvaluation {
    enum Reason { case ok, noFace, multipleFaces, lowQuality, badAngle, faceTooSmall }
    let isFocused: Bool
    let reason: Reason
}

struct FocusDetectionEvaluator: Sendable {
    var minFaceAreaRatio: CGFloat = 0.30
    var minQuality: Float = 0.4
    var maxRollDeg: Double = 25
    var maxYawDeg: Double = 30

    nonisolated func evaluate(observations: [VNFaceObservation], quality: Float?, kind: FocusDetectionKind) -> FocusEvaluation {
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

        if let q = quality, q < minQuality {
            return FocusEvaluation(isFocused: false, reason: .lowQuality)
        }

        let roll = face.roll.map { abs($0.doubleValue * 180 / .pi) } ?? 0
        let yaw = face.yaw.map { abs($0.doubleValue * 180 / .pi) } ?? 0
        let pitch = face.pitch.map { $0.doubleValue * 180 / .pi } ?? 0

        if roll > maxRollDeg || yaw > maxYawDeg {
            return FocusEvaluation(isFocused: false, reason: .badAngle)
        }

        let pitchOk: Bool
        switch kind {
        case .study:
            pitchOk = pitch >= -10 && pitch <= 25
        case .pcWork:
            pitchOk = pitch >= -15 && pitch <= 15
        }

        if !pitchOk {
            return FocusEvaluation(isFocused: false, reason: .badAngle)
        }

        return FocusEvaluation(isFocused: true, reason: .ok)
    }
}
