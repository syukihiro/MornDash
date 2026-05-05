import Foundation
import AVFoundation
import CoreVideo
import Vision
import Combine

@MainActor
final class FocusDetectionViewModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published private(set) var isDetected: Bool = false
    @Published private(set) var elapsedSeconds: Int
    @Published private(set) var statusReason: FocusEvaluation.Reason = .noFace
    @Published private(set) var hasReachedTarget: Bool = false

    let cameraManager: CameraManager
    let kind: FocusDetectionKind
    let targetSeconds: Int

    var onTick: ((Int) -> Void)?
    var onTargetReached: (() -> Void)?

    nonisolated(unsafe) private let faceRequest: VNDetectFaceRectanglesRequest
    nonisolated(unsafe) private let qualityRequest: VNDetectFaceCaptureQualityRequest
    nonisolated private let evaluator: FocusDetectionEvaluator
    private var consecutiveOk = 0
    private var consecutiveNg = 0
    private var tickTimer: Timer?
    nonisolated(unsafe) private var lastFrameProcessAt: Date?
    private let processIntervalSeconds: TimeInterval = 0.25

    init(kind: FocusDetectionKind, targetSeconds: Int, initialAccumulated: Int) {
        self.kind = kind
        self.targetSeconds = targetSeconds
        self.elapsedSeconds = initialAccumulated

        let req = VNDetectFaceRectanglesRequest()
        req.revision = VNDetectFaceRectanglesRequestRevision3
        self.faceRequest = req
        self.qualityRequest = VNDetectFaceCaptureQualityRequest()
        self.evaluator = FocusDetectionEvaluator()

        self.cameraManager = CameraManager()
        super.init()
        cameraManager.delegate = self
        cameraManager.checkPermission()
    }

    func start() {
        cameraManager.session.sessionPreset = .vga640x480
        cameraManager.startSession()
        startTickTimer()
    }

    func pause() {
        stopTickTimer()
        cameraManager.stopSession()
    }

    func stop() {
        stopTickTimer()
        onTick?(elapsedSeconds)
        cameraManager.stopSession()
    }

    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let now = Date()
        if let last = lastFrameProcessAt, now.timeIntervalSince(last) < processIntervalSeconds {
            return
        }
        lastFrameProcessAt = now

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        do {
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
            try handler.perform([faceRequest, qualityRequest])

            let observations = faceRequest.results ?? []
            let quality = qualityRequest.results?.first?.faceCaptureQuality

            let evaluation = evaluator.evaluate(observations: observations, quality: quality, kind: kind)

            Task { @MainActor [weak self] in
                self?.applyEvaluation(evaluation)
            }
        } catch {
            #if DEBUG
            print("[FocusDetection] vision perform failed: \(error)")
            #endif
        }
    }

    // MARK: - Private

    private func applyEvaluation(_ evaluation: FocusEvaluation) {
        statusReason = evaluation.reason
        if evaluation.isFocused {
            consecutiveOk += 1
            consecutiveNg = 0
            if consecutiveOk >= 3 {
                isDetected = true
            }
        } else {
            consecutiveNg += 1
            consecutiveOk = 0
            if consecutiveNg >= 5 {
                isDetected = false
            }
        }
    }

    private func startTickTimer() {
        stopTickTimer()
        tickTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
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
            onTargetReached?()
        }
    }
}
