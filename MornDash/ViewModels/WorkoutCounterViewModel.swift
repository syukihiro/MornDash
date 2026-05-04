import Foundation
import AVFoundation
import CoreVideo
import Vision
import Combine

/// スクワット限定のAIカウンター。VNDetectHumanBodyPoseRequest で首/鼻/肩のY座標を追跡し、
/// 立ち→しゃがみ→立ち の状態遷移で1回をカウントする。
/// 閾値は waiton (https://github.com/.../waiton) の PoseDetection と同値。
final class WorkoutCounterViewModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published private(set) var count: Int = 0
    @Published private(set) var feedbackMessage: String = NSLocalizedString("workout_status_recognizing", comment: "")
    @Published private(set) var hasReachedTarget: Bool = false

    let cameraManager = CameraManager()
    let targetReps: Int
    var onTargetReached: (() -> Void)?

    private let bodyPoseRequest = VNDetectHumanBodyPoseRequest()

    private enum Phase { case up, down }
    private var currentPhase: Phase = .up
    private var baselineY: CGFloat?
    private var isDetecting: Bool = true

    private static let movementThreshold: CGFloat = 0.15
    private static let hysteresisOffset: CGFloat = 0.05
    private static let minJointConfidence: Float = 0.3

    init(targetReps: Int) {
        self.targetReps = targetReps
        super.init()
        cameraManager.delegate = self
        cameraManager.checkPermission()
    }

    func start() {
        cameraManager.startSession()
    }

    func stop() {
        cameraManager.stopSession()
    }

    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        do {
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
            try handler.perform([bodyPoseRequest])

            guard let observation = bodyPoseRequest.results?.first else {
                publishStatus(NSLocalizedString("workout_status_no_body", comment: ""))
                return
            }
            processObservation(observation)
        } catch {
            #if DEBUG
            print("[WorkoutCounter] vision perform failed: \(error)")
            #endif
        }
    }

    // MARK: - Detection

    private func processObservation(_ observation: VNHumanBodyPoseObservation) {
        guard let recognized = try? observation.recognizedPoints(.all),
              let currentY = trackingY(in: recognized) else {
            publishStatus(NSLocalizedString("workout_status_adjust", comment: ""))
            return
        }

        guard isDetecting else { return }

        if baselineY == nil {
            baselineY = currentY
            publishStatus(NSLocalizedString("workout_status_start", comment: ""))
            return
        }

        guard let baseline = baselineY else { return }
        detectSquat(currentY: currentY, baseline: baseline)
    }

    private func trackingY(in points: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) -> CGFloat? {
        let conf = Self.minJointConfidence
        for joint in [VNHumanBodyPoseObservation.JointName.neck, .nose, .leftShoulder, .rightShoulder] {
            if let p = points[joint], p.confidence > conf {
                return p.location.y
            }
        }
        return nil
    }

    /// 立ち(高Y) → しゃがみ(低Y) → 立ち で1回カウント
    private func detectSquat(currentY: CGFloat, baseline: CGFloat) {
        switch currentPhase {
        case .up:
            if currentY < (baseline - Self.movementThreshold) {
                currentPhase = .down
                publishStatus(NSLocalizedString("workout_status_down", comment: ""))
            }
        case .down:
            if currentY > (baseline - Self.hysteresisOffset) {
                currentPhase = .up
                incrementCount()
            }
        }
    }

    private func incrementCount() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.count += 1
            self.feedbackMessage = NSLocalizedString("workout_status_good", comment: "")

            if self.count >= self.targetReps, !self.hasReachedTarget {
                self.hasReachedTarget = true
                self.isDetecting = false
                self.onTargetReached?()
            }
        }
    }

    private func publishStatus(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            self?.feedbackMessage = message
        }
    }
}
