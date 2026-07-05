import AVFoundation
import Combine
import UIKit

final class CameraManager: NSObject, ObservableObject {
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.morndash.cameraSessionQueue")

    @Published private(set) var isAuthorized = false
    @Published private(set) var permissionDenied = false

    weak var delegate: AVCaptureVideoDataOutputSampleBufferDelegate?
    private var isConfigured = false

    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorized = true
            permissionDenied = false
            configure()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.isAuthorized = granted
                    self?.permissionDenied = !granted
                }
                if granted {
                    self?.configure()
                }
            }
        default:
            DispatchQueue.main.async {
                self.isAuthorized = false
                self.permissionDenied = true
            }
        }
    }

    func configure(preset: AVCaptureSession.Preset = .high) {
        sessionQueue.async { [weak self] in
            self?.configureSessionIfNeeded(preset: preset)
        }
    }

    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.configureSessionIfNeeded()
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }

    private func configureSessionIfNeeded(preset: AVCaptureSession.Preset = .high) {
        if isConfigured {
            if session.sessionPreset != preset, session.canSetSessionPreset(preset) {
                session.beginConfiguration()
                session.sessionPreset = preset
                session.commitConfiguration()
            }
            return
        }

        session.beginConfiguration()
        if session.canSetSessionPreset(preset) {
            session.sessionPreset = preset
        }

        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
              session.canAddInput(videoDeviceInput) else {
            session.commitConfiguration()
            return
        }
        session.addInput(videoDeviceInput)

        let videoOutput = AVCaptureVideoDataOutput()
        guard session.canAddOutput(videoOutput) else {
            session.commitConfiguration()
            return
        }

        session.addOutput(videoOutput)
        videoOutput.alwaysDiscardsLateVideoFrames = true

        if let delegate {
            videoOutput.setSampleBufferDelegate(
                delegate,
                queue: DispatchQueue(label: "com.morndash.cameraOutputQueue")
            )
        }

        if let connection = videoOutput.connection(with: .video) {
            connection.videoRotationAngle = 90
            if connection.isVideoMirroringSupported {
                connection.automaticallyAdjustsVideoMirroring = false
                connection.isVideoMirrored = true
            }
        }

        session.commitConfiguration()
        isConfigured = true
    }
}
