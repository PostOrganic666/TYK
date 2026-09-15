import AVFoundation
import AppKit

/// A live camera preview with NO capture output of any kind. The session
/// has an input and a preview layer, nothing else, so there is
/// structurally nothing that could save or send an image.
@MainActor
final class PlayCameraController: ObservableObject {
    enum State {
        case checking
        case noCamera
        case denied
        case running
    }

    @Published var state: State = .checking

    let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "play-camera")

    /// Whether a parent already granted camera access. Sessions in front
    /// of a child should not prompt.
    static var accessAlreadyGranted: Bool {
        AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    }

    /// Start the preview. Prompts for permission only when `allowPrompt`.
    func start(allowPrompt: Bool = true) {
        guard Self.anyCamera() != nil else {
            state = .noCamera
            return
        }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureAndRun()
        case .notDetermined where allowPrompt:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                Task { @MainActor in
                    if granted { self.configureAndRun() } else { self.state = .denied }
                }
            }
        default:
            state = .denied
        }
    }

    func stop() {
        queue.async { [session] in
            if session.isRunning { session.stopRunning() }
        }
    }

    private static func anyCamera() -> AVCaptureDevice? {
        AVCaptureDevice.default(for: .video)
    }

    private func configureAndRun() {
        queue.async { [weak self] in
            guard let self else { return }
            self.session.beginConfiguration()
            self.session.inputs.forEach { self.session.removeInput($0) }
            if let device = Self.anyCamera(),
               let input = try? AVCaptureDeviceInput(device: device),
               self.session.canAddInput(input) {
                self.session.addInput(input)
            }
            // Deliberately: no outputs are ever added to this session.
            self.session.commitConfiguration()
            if !self.session.isRunning { self.session.startRunning() }
            Task { @MainActor in self.state = .running }
        }
    }
}

/// The preview layer host. `layer.filters` can carry Core Image filters
/// (sepia, pixellate, etc.) for on-screen effects; nothing is rendered to
/// a file.
final class CameraPreviewView: NSView {
    let previewLayer = AVCaptureVideoPreviewLayer()

    init(session: AVCaptureSession) {
        super.init(frame: .zero)
        wantsLayer = true
        previewLayer.session = session
        previewLayer.videoGravity = .resizeAspectFill
        layer = previewLayer
    }

    required init?(coder: NSCoder) { fatalError() }

    /// Mirror like a selfie camera.
    func setMirrored(_ mirrored: Bool) {
        previewLayer.connection?.automaticallyAdjustsVideoMirroring = false
        previewLayer.connection?.isVideoMirrored = mirrored
    }
}
