import AVFoundation
import Combine

final class CameraManager: NSObject, ObservableObject {
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.morndash.cameraSessionQueue")

    weak var delegate: AVCaptureVideoDataOutputSampleBufferDelegate?

    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    self?.setupSession()
                }
            }
        default:
            break
        }
    }

    private func setupSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.session.beginConfiguration()

            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
                  let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
                  self.session.canAddInput(videoDeviceInput) else {
                self.session.commitConfiguration()
                return
            }
            self.session.addInput(videoDeviceInput)

            let videoOutput = AVCaptureVideoDataOutput()
            if self.session.canAddOutput(videoOutput) {
                self.session.addOutput(videoOutput)
                videoOutput.alwaysDiscardsLateVideoFrames = true

                if let delegate = self.delegate {
                    videoOutput.setSampleBufferDelegate(delegate, queue: DispatchQueue(label: "com.morndash.cameraOutputQueue"))
                }

                if let connection = videoOutput.connection(with: .video) {
                    connection.videoRotationAngle = 90
                    if connection.isVideoMirroringSupported {
                        connection.automaticallyAdjustsVideoMirroring = false
                        connection.isVideoMirrored = true
                    }
                }
            }

            self.session.commitConfiguration()
            self.session.startRunning()
        }
    }

    func startSession() {
        sessionQueue.async {
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }

    func stopSession() {
        sessionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }
}
