import AppKit
import Foundation
import KeyboardShortcuts

@MainActor
final class AppController: ObservableObject {
    static let shared = AppController()

    @Published private(set) var isProcessing = false

    private let screenCaptureService: ScreenCaptureService
    private let textExtractor: any TextExtractionEngine
    private let clipboardService: ClipboardService

    private init(
        screenCaptureService: ScreenCaptureService = ScreenCaptureService(),
        textExtractor: any TextExtractionEngine = VisionTextExtractor(),
        clipboardService: ClipboardService = ClipboardService()
    ) {
        self.screenCaptureService = screenCaptureService
        self.textExtractor = textExtractor
        self.clipboardService = clipboardService

        KeyboardShortcuts.onKeyUp(for: .captureSelection) { [weak self] in
            Task { @MainActor in
                self?.captureText()
            }
        }
    }

    func captureText() {
        guard !isProcessing else {
            return
        }

        Task {
            await runCaptureFlow()
        }
    }

    private func runCaptureFlow() async {
        guard !isProcessing else {
            return
        }

        isProcessing = true
        defer { isProcessing = false }

        do {
            let captureURL = try await screenCaptureService.captureInteractiveSelection()
            defer {
                try? FileManager.default.removeItem(at: captureURL)
            }

            let extractedText = try await textExtractor.extractText(from: captureURL)
            clipboardService.copy(extractedText)

            if AppPreferences.playSuccessSound {
                NSSound(named: "Glass")?.play()
            }
        } catch TextExtractionError.captureCancelled {
            return
        } catch {
            presentFailure(error)
        }
    }

    private func presentFailure(_ error: Error) {
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.messageText = "Text extraction failed"
        alert.informativeText = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        alert.alertStyle = .warning
        alert.runModal()
    }
}
