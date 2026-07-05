import Foundation
import AVFoundation
import CoreVideo
import Vision
import Combine

enum FocusSessionPhase: Equatable {
    case initializing
    case searching
    case aligning
    case calibrating(progress: Double)
    case countdown(Int)
    case go
    case active
    case completed
}

final class FocusDetectionViewModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published private(set) var isDetected: Bool = false
    @Published private(set) var elapsedSeconds: Int
    @Published private(set) var statusReason: FocusEvaluation.Reason = .noFace
    @Published private(set) var hasReachedTarget: Bool = false
    @Published private(set) var faceBoundingBox: CGRect?
    @Published private(set) var sessionPhase: FocusSessionPhase = .initializing
    @Published private(set) var feedbackMessage: String = NSLocalizedString("workout_status_recognizing", comment: "")

    let cameraManager: CameraManager
    let targetSeconds: Int

    var onTick: ((Int) -> Void)?
    var onTargetReached: (() -> Void)?

    private let detectionKind: FocusDetectionKind
    private let faceRequest = VNDetectFaceRectanglesRequest()
    private let evaluator = FocusDetectionEvaluator()
    private var consecutiveOk = 0
    private var consecutiveNg = 0
    private var tickTimer: Timer?
    private var lastFrameProcessAt: Date?
    private let processIntervalSeconds: TimeInterval = 0.25

    private var hasFinishedSetup = false
    private var isRunningCountdown = false
    private var countdownGeneration = 0
    private var calibrationStableCount = 0
    private let stateLock = NSLock()

    private static let calibrationStableSamples = 8

    init(kind: FocusDetectionKind, targetSeconds: Int, initialAccumulated: Int) {
        self.detectionKind = kind
        self.targetSeconds = targetSeconds
        self.elapsedSeconds = initialAccumulated

        faceRequest.revision = VNDetectFaceRectanglesRequestRevision3

        self.cameraManager = CameraManager()
        super.init()
        cameraManager.delegate = self
        cameraManager.checkPermission()
    }

    func start() {
        cameraManager.configure(preset: .vga640x480)
        cameraManager.startSession()
    }

    func pause() {
        stopTickTimer()
        cameraManager.stopSession()
    }

    func stop() {
        stateLock.lock()
        countdownGeneration += 1
        stateLock.unlock()
        stopTickTimer()
        DispatchQueue.main.async { [weak self] in
            self?.onTick?(self?.elapsedSeconds ?? 0)
        }
        cameraManager.stopSession()
    }

    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let now = Date()
        if let last = lastFrameProcessAt, now.timeIntervalSince(last) < processIntervalSeconds {
            return
        }
        lastFrameProcessAt = now

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        do {
            let handler = VNImageRequestHandler(
                cvPixelBuffer: pixelBuffer,
                orientation: .leftMirrored,
                options: [:]
            )
            try handler.perform([faceRequest])

            let observations = faceRequest.results ?? []
            let evaluation = evaluator.evaluate(
                observations: observations,
                kind: detectionKind
            )
            let boundingBox = observations.first?.boundingBox

            DispatchQueue.main.async { [weak self] in
                self?.faceBoundingBox = boundingBox
                self?.handleFrame(evaluation: evaluation, hasFace: !observations.isEmpty)
            }
        } catch {
            #if DEBUG
            print("[FocusDetection] vision perform failed: \(error)")
            #endif
        }
    }

    // MARK: - Private

    private func handleFrame(evaluation: FocusEvaluation, hasFace: Bool) {
        guard !hasReachedTarget else { return }

        if hasFinishedSetup {
            applyEvaluation(evaluation)
            return
        }

        if isRunningCountdown { return }

        if !hasFace {
            resetCalibration()
            publishPhase(.searching)
            publishStatus(NSLocalizedString("focus_status_no_face", comment: ""))
            return
        }

        if evaluation.isFocused {
            advanceCalibration()
        } else {
            resetCalibration()
            publishPhase(.aligning)
            publishStatus(statusMessage(for: evaluation.reason))
        }
    }

    private func advanceCalibration() {
        guard !isRunningCountdown, !hasFinishedSetup else { return }

        if calibrationStableCount == 0 {
            publishPhase(.calibrating(progress: 0))
            publishStatus(NSLocalizedString("focus_status_hold_still", comment: ""))
        }

        calibrationStableCount += 1
        let progress = min(1, Double(calibrationStableCount) / Double(Self.calibrationStableSamples))
        publishPhase(.calibrating(progress: progress))

        if calibrationStableCount >= Self.calibrationStableSamples {
            beginCountdown()
        }
    }

    private func beginCountdown() {
        guard !isRunningCountdown, !hasFinishedSetup else { return }

        isRunningCountdown = true
        stateLock.lock()
        countdownGeneration += 1
        let generation = countdownGeneration
        stateLock.unlock()

        publishPhase(.countdown(3))
        publishStatus(NSLocalizedString("workout_status_countdown", comment: ""))
        scheduleCountdownTick(3, generation: generation)
    }

    private func scheduleCountdownTick(_ seconds: Int, generation: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self else { return }
            self.stateLock.lock()
            let isCurrent = generation == self.countdownGeneration
            self.stateLock.unlock()
            guard isCurrent, !self.hasReachedTarget else { return }

            if seconds > 1 {
                self.publishPhase(.countdown(seconds - 1))
                self.scheduleCountdownTick(seconds - 1, generation: generation)
                return
            }

            self.publishPhase(.go)
            self.publishStatus(NSLocalizedString("workout_countdown_go", comment: ""))
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
                guard let self else { return }
                self.stateLock.lock()
                let isCurrent = generation == self.countdownGeneration
                self.stateLock.unlock()
                guard isCurrent, !self.hasReachedTarget else { return }

                self.hasFinishedSetup = true
                self.isRunningCountdown = false
                self.publishPhase(.active)
                self.publishStatus(NSLocalizedString("focus_status_ready_hint", comment: ""))
                self.startTickTimer()
            }
        }
    }

    private func resetCalibration() {
        guard !hasFinishedSetup, !isRunningCountdown else { return }
        calibrationStableCount = 0
    }

    private func applyEvaluation(_ evaluation: FocusEvaluation) {
        statusReason = evaluation.reason
        if evaluation.isFocused {
            consecutiveOk += 1
            consecutiveNg = 0
            if consecutiveOk >= 3 {
                isDetected = true
                feedbackMessage = NSLocalizedString("focus_status_detected", comment: "")
            }
        } else {
            consecutiveNg += 1
            consecutiveOk = 0
            if consecutiveNg >= 5 {
                isDetected = false
                feedbackMessage = statusMessage(for: evaluation.reason)
            }
        }
    }

    private func statusMessage(for reason: FocusEvaluation.Reason) -> String {
        switch reason {
        case .ok:
            return NSLocalizedString("focus_status_detected", comment: "")
        case .noFace:
            return NSLocalizedString("focus_status_no_face", comment: "")
        case .multipleFaces:
            return NSLocalizedString("focus_status_multiple_faces", comment: "")
        case .lowQuality:
            return NSLocalizedString("focus_status_low_quality", comment: "")
        case .badAngle:
            return NSLocalizedString("focus_status_bad_angle", comment: "")
        case .faceTooSmall:
            return NSLocalizedString("focus_status_face_too_small", comment: "")
        }
    }

    private func startTickTimer() {
        stopTickTimer()
        tickTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.tick()
            }
        }
    }

    private func stopTickTimer() {
        tickTimer?.invalidate()
        tickTimer = nil
    }

    private func tick() {
        guard isDetected else { return }
        elapsedSeconds += 1
        if elapsedSeconds % 5 == 0 {
            onTick?(elapsedSeconds)
        }
        if elapsedSeconds >= targetSeconds && !hasReachedTarget {
            hasReachedTarget = true
            publishPhase(.completed)
            stopTickTimer()
            onTargetReached?()
        }
    }

    private func publishStatus(_ message: String) {
        feedbackMessage = message
    }

    private func publishPhase(_ phase: FocusSessionPhase) {
        sessionPhase = phase
    }
}
