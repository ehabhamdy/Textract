import Foundation
import ImageIO
import Vision

struct VisionTextExtractor: TextExtractionEngine {
    func extractText(from imageURL: URL) async throws -> String {
        let preserveLineBreaks = AppPreferences.preserveLineBreaks
        let recognitionLanguages = AppPreferences.recognitionLanguages
        let customWords = AppPreferences.customWords

        let extractedText = try await Task.detached(priority: .userInitiated) {
            let configuration = OCRConfiguration(
                preserveLineBreaks: preserveLineBreaks,
                recognitionLanguages: recognitionLanguages,
                customWords: customWords
            )

            guard let source = CGImageSourceCreateWithURL(imageURL as CFURL, nil),
                  let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
                throw TextExtractionError.imageLoadFailed
            }

            let imageData = try Data(contentsOf: imageURL)

            var genericText: String?
            var genericError: Error?

            do {
                genericText = try performGenericTextRecognition(on: image, configuration: configuration)
            } catch {
                genericError = error
            }

            if #available(macOS 26.0, *) {
                let structuredExtractor = StructuredDocumentExtractor(configuration: configuration)
                if let preferredText = try await structuredExtractor.extractPreferredText(from: imageData, fallbackText: genericText) {
                    return preferredText
                }
            }

            if let genericText {
                return genericText
            }

            if let genericError {
                throw genericError
            }

            throw TextExtractionError.noTextFound
        }.value

        let normalizedOutput = extractedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedOutput.isEmpty else {
            throw TextExtractionError.noTextFound
        }

        return normalizedOutput
    }

    private func performGenericTextRecognition(on image: CGImage, configuration: OCRConfiguration) throws -> String {
        var capturedError: Error?
        var textOutput = ""

        let request = VNRecognizeTextRequest { request, error in
            if let error {
                capturedError = error
                return
            }

            let observations = request.results as? [VNRecognizedTextObservation] ?? []
            textOutput = TextPostProcessor(preserveLineBreaks: configuration.preserveLineBreaks).process(observations)
        }

        request.recognitionLevel = .accurate
        request.automaticallyDetectsLanguage = true
        request.usesLanguageCorrection = true
        request.recognitionLanguages = configuration.recognitionLanguages
        request.customWords = configuration.customWords

        try VNImageRequestHandler(cgImage: image).perform([request])

        if let capturedError {
            throw capturedError
        }

        let normalizedOutput = textOutput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedOutput.isEmpty else {
            throw TextExtractionError.noTextFound
        }

        return normalizedOutput
    }
}

struct OCRConfiguration: Sendable {
    let preserveLineBreaks: Bool
    let recognitionLanguages: [String]
    let customWords: [String]
}
