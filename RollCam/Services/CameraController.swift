import AVFoundation
import SwiftUI
import Observation

// Thin AVFoundation wrapper. If the camera can't be configured (Simulator,
// permission denied, no device), `isAvailable` stays false and the recording
// screen falls back to the prototype's simulated cinematic background — the
// HR stream, timer and controls all still work.
@Observable
final class CameraController {
    var isAvailable = false
    var isRecording = false
    var lastRecordingURL: URL?
    var usingFrontCamera = false
    // True when the user has denied (or restricted) camera access — the view
    // uses this to guide them to Settings instead of silently falling back.
    var permissionDenied = false

    @ObservationIgnored let session = AVCaptureSession()
    @ObservationIgnored private let movieOutput = AVCaptureMovieFileOutput()
    @ObservationIgnored private let queue = DispatchQueue(label: "com.rejkavaz.RollCam.camera")
    @ObservationIgnored private lazy var recordingDelegate = RecordingDelegate { [weak self] url in
        DispatchQueue.main.async {
            self?.isRecording = false
            if let url { self?.lastRecordingURL = url }
            let completion = self?.finishCompletion
            self?.finishCompletion = nil
            completion?(url)
        }
    }
    @ObservationIgnored private var videoInput: AVCaptureDeviceInput?
    @ObservationIgnored private var configured = false
    @ObservationIgnored private var finishCompletion: ((URL?) -> Void)?
    // Recording can be requested before the capture session finishes its async
    // configuration. We remember the intent and start as soon as it's ready.
    @ObservationIgnored private var wantsRecording = false

    // MARK: Lifecycle

    func configureIfNeeded() {
        guard !configured else { return }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configure()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted { self?.configure() }
                else { DispatchQueue.main.async { self?.permissionDenied = true } }
            }
        default:
            // Denied / restricted — surface a prompt to open Settings.
            DispatchQueue.main.async { self.permissionDenied = true }
        }
    }

    private func configure() {
        queue.async { [weak self] in
            guard let self else { return }
            self.session.beginConfiguration()
            self.session.sessionPreset = .high

            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let input = try? AVCaptureDeviceInput(device: camera),
                  self.session.canAddInput(input) else {
                self.session.commitConfiguration()
                return
            }
            self.session.addInput(input)
            self.videoInput = input

            if let mic = AVCaptureDevice.default(for: .audio),
               let micInput = try? AVCaptureDeviceInput(device: mic),
               self.session.canAddInput(micInput) {
                self.session.addInput(micInput)
            }

            if self.session.canAddOutput(self.movieOutput) {
                self.session.addOutput(self.movieOutput)
            }

            self.session.commitConfiguration()
            self.configured = true
            self.session.startRunning()
            DispatchQueue.main.async {
                self.isAvailable = true
                // If the recording screen asked to record before we were ready,
                // honour that intent now that the session is live.
                if self.wantsRecording { self.startRecording() }
            }
        }
    }

    func start() {
        guard configured else { return }
        queue.async { if !self.session.isRunning { self.session.startRunning() } }
    }

    func stop() {
        queue.async { if self.session.isRunning { self.session.stopRunning() } }
    }

    func flip() {
        guard configured, let current = videoInput else { return }
        queue.async { [weak self] in
            guard let self else { return }
            self.session.beginConfiguration()
            self.session.removeInput(current)
            let position: AVCaptureDevice.Position = self.usingFrontCamera ? .back : .front
            if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
               let input = try? AVCaptureDeviceInput(device: device),
               self.session.canAddInput(input) {
                self.session.addInput(input)
                self.videoInput = input
                DispatchQueue.main.async { self.usingFrontCamera.toggle() }
            } else {
                self.session.addInput(current)
            }
            self.session.commitConfiguration()
        }
    }

    // MARK: Recording

    func startRecording() {
        // Not configured yet — remember the intent; configure() will start us.
        guard isAvailable else { wantsRecording = true; return }
        guard !movieOutput.isRecording else { return }
        wantsRecording = false
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("roll-\(Int(Date().timeIntervalSince1970)).mov")
        movieOutput.startRecording(to: url, recordingDelegate: recordingDelegate)
        isRecording = true
    }

    func stopRecording() {
        guard movieOutput.isRecording else { return }
        movieOutput.stopRecording()
    }

    /// Stop recording and call `completion` once the file is fully written.
    /// If nothing was recording (e.g. Simulator), completion fires immediately
    /// with whatever URL we have (usually nil) so the session still saves.
    func finishRecording(_ completion: @escaping (URL?) -> Void) {
        guard movieOutput.isRecording else {
            completion(lastRecordingURL)
            return
        }
        finishCompletion = completion
        movieOutput.stopRecording()
    }
}

// AVCaptureFileOutputRecordingDelegate must live on an NSObject.
final class RecordingDelegate: NSObject, AVCaptureFileOutputRecordingDelegate {
    private let onFinish: (URL?) -> Void
    init(onFinish: @escaping (URL?) -> Void) { self.onFinish = onFinish }

    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection], error: Error?) {
        // AVCaptureMovieFileOutput delivers a non-nil error on almost every
        // successful stop. The recording is still usable when the error carries
        // AVErrorRecordingSuccessfullyFinishedKey == true — treating any error
        // as failure (the old behaviour) silently discarded every clip.
        var usable = error == nil
        if let nsError = error as NSError? {
            usable = (nsError.userInfo[AVErrorRecordingSuccessfullyFinishedKey] as? Bool) ?? false
        }
        // Final guard: the file must exist and actually contain data.
        let attrs = try? FileManager.default.attributesOfItem(atPath: outputFileURL.path)
        let size = (attrs?[.size] as? Int) ?? 0
        onFinish(usable && size > 0 ? outputFileURL : nil)
    }
}

// MARK: - SwiftUI preview layer

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }
    func updateUIView(_ uiView: PreviewView, context: Context) {}

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}
