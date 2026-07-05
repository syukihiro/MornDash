import Foundation
import AVFoundation
import CoreVideo
import Vision
import Combine

enum WorkoutSessionPhase: Equatable {
    case initializing
    case searching
    case aligning
    case calibrating(progress: Double)
    case countdown(Int)
    case go
    case active
    case completed
}

/// スクワット限定のAIカウンター。VNDetectHumanBodyPoseRequest で首/鼻/肩のY座標を追跡し、
/// 立ち→しゃがみ→立ち の状態遷移で1回をカウントする。
/// 閾値は waiton の PoseDetection と同値。
final class WorkoutCounterViewModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published private(set) var count: Int = 0
    @Published private(set) var feedbackMessage: String = NSLocalizedString("workout_status_recognizing", comment: "")
    @Published private(set) var hasReachedTarget: Bool = false
    @Published private(set) var poseJoints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
    @Published private(set) var sessionPhase: WorkoutSessionPhase = .initializing

    let cameraManager = CameraManager()
    let targetReps: Int
    var onTargetReached: (() -> Void)?

    private let bodyPoseRequest = VNDetectHumanBodyPoseRequest()

    private enum Phase { case up, down }
    private var currentPhase: Phase = .up
    private var baselineY: CGFloat?
    private var isDetecting = false

    private var calibrationSamples: [CGFloat] = []
    private var stableFrameCount = 0
    private var countdownGeneration = 0
    private var hasFinishedSetup = false
    private var isRunningCountdown = false
    private let processingLock = NSLock()

    private static let movementThreshold: CGFloat = 0.15
    private static let hysteresisOffset: CGFloat = 0.05
    private static let minJointConfidence: Float = 0.3
    private static let calibrationStableFrames = 24
    private static let calibrationMovementTolerance: CGFloat = 0.025

    init(targetReps: Int) {
        self.targetReps = targetReps
        super.init()
        cameraManager.delegate = self
        cameraManager.checkPermission()
    }

    func start() {
        cameraManager.configure(preset: .high)
        cameraManager.startSession()
    }

    func stop() {
        countdownGeneration += 1
        cameraManager.stopSession()
    }

    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        do {
            let handler = VNImageRequestHandler(
                cvPixelBuffer: pixelBuffer,
                orientation: .leftMirrored,
                options: [:]
            )
            try handler.perform([bodyPoseRequest])

            guard let observation = bodyPoseRequest.results?.first else {
                publishPoseJoints([:])
                resetCalibration()
                publishPhase(.searching)
                publishStatus(NSLocalizedString("workout_status_no_body", comment: ""))
                return
            }

            let joints = extractJoints(from: observation)
            publishPoseJoints(joints)
            processObservation(observation)
        } catch {
            #if DEBUG
            print("[WorkoutCounter] vision perform failed: \(error)")
            #endif
        }
    }

    // MARK: - Detection

    private func processObservation(_ observation: VNHumanBodyPoseObservation) {
        processingLock.lock()
        let finishedSetup = hasFinishedSetup
        let runningCountdown = isRunningCountdown
        processingLock.unlock()

        guard !hasReachedTarget else { return }

        guard let recognized = try? observation.recognizedPoints(.all),
              let currentY = trackingY(in: recognized) else {
            if !finishedSetup && !runningCountdown {
                resetCalibration()
                publishPhase(.aligning)
                publishStatus(NSLocalizedString("workout_status_adjust", comment: ""))
            }
            return
        }

        if finishedSetup {
            guard isDetecting, let baseline = baselineY else { return }
            detectSquat(currentY: currentY, baseline: baseline)
            return
        }

        guard !runningCountdown else { return }
        advanceCalibration(currentY: currentY)
    }

    private func advanceCalibration(currentY: CGFloat) {
        guard baselineY == nil else { return }

        if calibrationSamples.isEmpty {
            publishPhase(.calibrating(progress: 0))
            publishStatus(NSLocalizedString("workout_status_stand_still", comment: ""))
        }

        if let last = calibrationSamples.last,
           abs(currentY - last) > Self.calibrationMovementTolerance {
            stableFrameCount = 0
            calibrationSamples.removeAll(keepingCapacity: true)
        }

        calibrationSamples.append(currentY)
        stableFrameCount += 1

        let progress = min(1, Double(stableFrameCount) / Double(Self.calibrationStableFrames))
        publishPhase(.calibrating(progress: progress))

        if stableFrameCount >= Self.calibrationStableFrames {
            baselineY = calibrationSamples.reduce(0, +) / CGFloat(calibrationSamples.count)
            beginCountdown()
        }
    }

    private func beginCountdown() {
        processingLock.lock()
        isRunningCountdown = true
        processingLock.unlock()

        countdownGeneration += 1
        let generation = countdownGeneration
        publishPhase(.countdown(3))
        publishStatus(NSLocalizedString("workout_status_countdown", comment: ""))
        scheduleCountdownTick(3, generation: generation)
    }

    private func scheduleCountdownTick(_ seconds: Int, generation: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self, generation == self.countdownGeneration, !self.hasReachedTarget else { return }

            if seconds > 1 {
                self.publishPhase(.countdown(seconds - 1))
                self.scheduleCountdownTick(seconds - 1, generation: generation)
                return
            }

            self.publishPhase(.go)
            self.publishStatus(NSLocalizedString("workout_countdown_go", comment: ""))
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
                guard let self, generation == self.countdownGeneration, !self.hasReachedTarget else { return }
                self.processingLock.lock()
                self.hasFinishedSetup = true
                self.isRunningCountdown = false
                self.processingLock.unlock()
                self.isDetecting = true
                self.currentPhase = .up
                self.publishPhase(.active)
                self.publishStatus(NSLocalizedString("workout_status_ready_hint", comment: ""))
            }
        }
    }

    private func resetCalibration() {
        processingLock.lock()
        hasFinishedSetup = false
        isRunningCountdown = false
        processingLock.unlock()

        calibrationSamples.removeAll(keepingCapacity: true)
        stableFrameCount = 0
        baselineY = nil
        isDetecting = false
        currentPhase = .up
    }

    private func extractJoints(from observation: VNHumanBodyPoseObservation) -> [VNHumanBodyPoseObservation.JointName: CGPoint] {
        guard let points = try? observation.recognizedPoints(.all) else { return [:] }
        var joints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
        for (name, point) in points where point.confidence > Self.minJointConfidence {
            joints[name] = point.location
        }
        return joints
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
                self.publishPhase(.completed)
                self.onTargetReached?()
            }
        }
    }

    private func publishStatus(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            self?.feedbackMessage = message
        }
    }

    private func publishPhase(_ phase: WorkoutSessionPhase) {
        DispatchQueue.main.async { [weak self] in
            self?.sessionPhase = phase
        }
    }

    private func publishPoseJoints(_ joints: [VNHumanBodyPoseObservation.JointName: CGPoint]) {
        DispatchQueue.main.async { [weak self] in
            self?.poseJoints = joints
        }
    }
}
