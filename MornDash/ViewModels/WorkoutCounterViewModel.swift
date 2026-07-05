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
/// ロジックは waiton の detectSquat と同一。閾値は感度向上のため waiton(0.15)より緩めの 0.10。
final class WorkoutCounterViewModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published private(set) var count: Int = 0
    @Published private(set) var feedbackMessage: String = NSLocalizedString("workout_status_recognizing", comment: "")
    @Published private(set) var hasReachedTarget: Bool = false
    @Published private(set) var poseJoints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
    @Published private(set) var sessionPhase: WorkoutSessionPhase = .initializing

    let cameraManager = CameraManager()
    let targetReps: Int
    var onTargetReached: (() -> Void)?

    /// カウント検出用。回転済みバッファに .up で回し、縦移動を Y 軸に乗せる。
    private let bodyPoseRequest = VNDetectHumanBodyPoseRequest()
    /// 骨格線オーバーレイ描画用。layerRectConverted が期待する座標系に合わせ .leftMirrored で回す。
    /// 検出とは必要な向きが逆のため別リクエストにしている。
    private let overlayPoseRequest = VNDetectHumanBodyPoseRequest()

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

    private static let movementThreshold: CGFloat = 0.10
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

        // --- 骨格線オーバーレイ用 ---
        // 描画は layerRectConverted(fromMetadataOutputRect:) 経由で行うため、その期待する
        // 横向き座標系に一致する .leftMirrored で抽出する。検出とは向きが逆なので別ハンドラ。
        let overlayHandler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: .leftMirrored,
            options: [:]
        )
        if (try? overlayHandler.perform([overlayPoseRequest])) != nil,
           let overlayObservation = overlayPoseRequest.results?.first {
            publishPoseJoints(extractJoints(from: overlayObservation))
        } else {
            publishPoseJoints([:])
        }

        // --- カウント検出用 ---
        // CameraManager 側で videoRotationAngle=90 + ミラーを適用済みのため、ここに届くバッファは
        // 既に縦向き・ミラー済み。Vision で再度回転を掛けると立ち↔しゃがみの縦移動が Y ではなく
        // X 軸に乗って全くカウントされない。回転済みバッファには .up を使う（waiton の検出パスと同座標系）。
        do {
            let handler = VNImageRequestHandler(
                cvPixelBuffer: pixelBuffer,
                orientation: .up,
                options: [:]
            )
            try handler.perform([bodyPoseRequest])

            guard let observation = bodyPoseRequest.results?.first else {
                handleMissingBody()
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

    /// ボディを一時的に見失ったときの処理。セットアップ完了後(検出中)やカウントダウン中は
    /// baseline を捨てずに復帰を待つ。これをしないと1フレームのロストでキャリブレーションから
    /// やり直し(再度3秒カウントダウン)になり、進行中のレップも失われる。
    private func handleMissingBody() {
        processingLock.lock()
        let finishedSetup = hasFinishedSetup
        let runningCountdown = isRunningCountdown
        processingLock.unlock()

        guard !hasReachedTarget else { return }

        if finishedSetup || runningCountdown {
            publishStatus(NSLocalizedString("workout_status_no_body", comment: ""))
            return
        }

        resetCalibration()
        publishPhase(.searching)
        publishStatus(NSLocalizedString("workout_status_no_body", comment: ""))
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
