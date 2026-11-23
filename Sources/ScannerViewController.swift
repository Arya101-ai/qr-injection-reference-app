import AVFoundation
import UIKit

/// Full-screen camera preview that decodes QR codes with AVCaptureMetadataOutput,
/// the same API the client's app uses, so LambdaTest image injection is exercised
/// the same way.
final class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onCode: ((String) -> Void)?
    var onFailure: ((String) -> Void)?
    var onCancel: (() -> Void)?

    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "qr.scanner.session")
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var setupError: String?
    private var finished = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        view.accessibilityIdentifier = "scannerView"

        configureSession()
        addCloseButton()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let setupError {
            finish { self.onFailure?(setupError) }
            return
        }
        let session = self.session
        sessionQueue.async {
            if !session.isRunning { session.startRunning() }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSession()
    }

    private func configureSession() {
        guard let device = AVCaptureDevice.default(for: .video) else {
            setupError = "No camera available"
            return
        }
        let input: AVCaptureDeviceInput
        do {
            input = try AVCaptureDeviceInput(device: device)
        } catch {
            setupError = "Cannot open camera: \(error.localizedDescription)"
            return
        }

        guard session.canAddInput(input) else {
            setupError = "Cannot use camera input"
            return
        }
        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else {
            setupError = "Cannot read QR codes"
            return
        }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        // Must be set after the output is added to the session.
        guard output.availableMetadataObjectTypes.contains(.qr) else {
            setupError = "QR detection not supported"
            return
        }
        output.metadataObjectTypes = [.qr]

        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        view.layer.insertSublayer(layer, at: 0)
        previewLayer = layer
    }

    private func addCloseButton() {
        var config = UIButton.Configuration.filled()
        config.title = "Close"
        config.baseBackgroundColor = UIColor.black.withAlphaComponent(0.6)
        let close = UIButton(configuration: config)
        close.accessibilityIdentifier = "closeScanner"
        close.addAction(UIAction { [weak self] _ in
            self?.finish { self?.onCancel?() }
        }, for: .touchUpInside)
        close.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(close)
        NSLayoutConstraint.activate([
            close.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            close.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
        ])
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard
            let code = metadataObjects
                .compactMap({ $0 as? AVMetadataMachineReadableCodeObject })
                .first(where: { $0.type == .qr }),
            let payload = code.stringValue
        else { return }
        finish { self.onCode?(payload) }
    }

    /// Runs `action` once, after stopping the camera.
    private func finish(_ action: @escaping () -> Void) {
        guard !finished else { return }
        finished = true
        stopSession()
        DispatchQueue.main.async(execute: action)
    }

    private func stopSession() {
        let session = self.session
        sessionQueue.async {
            if session.isRunning { session.stopRunning() }
        }
    }
}
