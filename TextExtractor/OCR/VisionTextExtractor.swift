import Foundation
import ImageIO
import Vision

struct VisionTextExtractor: TextExtractionEngine {
    func extractText(from imageURL: URL) async throws -> String {
        let preserveLineBreaks = AppPreferences.preserveLineBreaks
        let recognitionLanguages = AppPreferences.recognitionLanguages
        let customWords = AppPreferences.customWords

        let extractedText = try await Task.detached(priority: .userInitiated) {
            guard let source = CGImageSourceCreateWithURL(imageURL as CFURL, nil),
                  let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
                throw TextExtractionError.imageLoadFailed
            }

            var capturedError: Error?
            var textOutput = ""

            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    capturedError = error
                    return
                }

                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                textOutput = TextPostProcessor(preserveLineBreaks: preserveLineBreaks).process(observations)
            }

            request.recognitionLevel = .accurate
            request.automaticallyDetectsLanguage = true
            request.usesLanguageCorrection = true
            request.recognitionLanguages = recognitionLanguages
            request.customWords = customWords

            try VNImageRequestHandler(cgImage: image).perform([request])

            if let capturedError {
                throw capturedError
            }

            return textOutput
        }.value

        let normalizedOutput = extractedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedOutput.isEmpty else {
            throw TextExtractionError.noTextFound
        }

        return normalizedOutput
    }
}
