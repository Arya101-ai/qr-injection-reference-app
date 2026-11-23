import AVFoundation
import UIKit

/// Home screen. Its accessibility IDs match the selectors in
/// qr-injection-test/test/specs/qr-injection.e2e.ts:
///   ~QRButton  -> button that opens the scanner
///   ~enterText -> UITextView whose value becomes "QR Code detected: <payload>"
final class MainViewController: UIViewController {
    private let scanButton = UIButton(type: .system)
    private let resultView = UITextView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let title = UILabel()
        title.text = "QR Injection Reference"
        title.font = .preferredFont(forTextStyle: .title2)
        title.textAlignment = .center

        var config = UIButton.Configuration.filled()
        config.title = "Scan QR Code"
        config.cornerStyle = .large
        scanButton.configuration = config
        scanButton.accessibilityIdentifier = "QRButton"
        scanButton.addTarget(self, action: #selector(scanTapped), for: .touchUpInside)

        resultView.text = "Waiting for scan"
        resultView.isEditable = false
        resultView.isScrollEnabled = false
        resultView.font = .preferredFont(forTextStyle: .body)
        resultView.textAlignment = .center
        resultView.layer.borderColor = UIColor.separator.cgColor
        resultView.layer.borderWidth = 1
        resultView.layer.cornerRadius = 8
        resultView.accessibilityIdentifier = "enterText"

        let stack = UIStackView(arrangedSubviews: [title, scanButton, resultView])
        stack.axis = .vertical
        stack.spacing = 24
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            scanButton.heightAnchor.constraint(equalToConstant: 50),
            resultView.heightAnchor.constraint(greaterThanOrEqualToConstant: 80),
        ])
    }

    @objc private func scanTapped() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            presentScanner()
        case .notDetermined:
            // Shows the system camera permission alert ("Allow" / "OK").
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    granted ? self.presentScanner() : self.show("Camera access denied")
                }
            }
        default:
            show("Camera access denied")
        }
    }

    private func presentScanner() {
        let scanner = ScannerViewController()
        scanner.modalPresentationStyle = .fullScreen
        scanner.onCode = { [weak self] payload in
            self?.dismiss(animated: true) {
                self?.show("QR Code detected: \(payload)")
            }
        }
        scanner.onFailure = { [weak self] message in
            self?.dismiss(animated: true) {
                self?.show("Scanner error: \(message)")
            }
        }
        scanner.onCancel = { [weak self] in
            self?.dismiss(animated: true)
        }
        present(scanner, animated: true)
    }

    private func show(_ text: String) {
        resultView.text = text
        UIAccessibility.post(notification: .layoutChanged, argument: resultView)
    }
}
