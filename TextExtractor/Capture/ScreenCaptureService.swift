import Foundation

struct ScreenCaptureService {
    func captureInteractiveSelection() async throws -> URL {
        let destinationURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("textract-\(UUID().uuidString)")
            .appendingPathExtension("png")

        do {
            try await runScreencapture(to: destinationURL)
        } catch {
            try? FileManager.default.removeItem(at: destinationURL)
            throw error
        }

        guard FileManager.default.fileExists(atPath: destinationURL.path) else {
            throw TextExtractionError.captureCancelled
        }

        return destinationURL
    }

    private func runScreencapture(to destinationURL: URL) async throws {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
            process.arguments = ["-i", "-x", destinationURL.path]

            process.terminationHandler = { terminatedProcess in
                let fileExists = FileManager.default.fileExists(atPath: destinationURL.path)

                if terminatedProcess.terminationStatus == 0 {
                    continuation.resume(returning: ())
                    return
                }

                if !fileExists {
                    continuation.resume(throwing: TextExtractionError.captureCancelled)
                    return
                }

                continuation.resume(
                    throwing: TextExtractionError.captureFailed(
                        "screencapture exited with status \(terminatedProcess.terminationStatus)."
                    )
                )
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
