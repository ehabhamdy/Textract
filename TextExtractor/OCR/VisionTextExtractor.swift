import Foundation
import ImageIO
import Vision

struct VisionTextExtractor: TextExtractionEngine {
    func extractText(from imageURL: URL) async throws -> String {
        let mode = AppPreferences.ocrMode
        let preserveLineBreaks = AppPreferences.preserveLineBreaks
        let recognitionLanguages = AppPreferences.recognitionLanguages
        let customWords = AppPreferences.customWords

        let extractedText = try await Task.detached(priority: .userInitiated) {
            let configuration = OCRConfiguration(
                mode: mode,
                preserveLineBreaks: preserveLineBreaks,
                recognitionLanguages: recognitionLanguages,
                customWords: customWords
            )

            guard let source = CGImageSourceCreateWithURL(imageURL as CFURL, nil),
                  let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
                throw TextExtractionError.imageLoadFailed
            }

            let genericResult = Result<String, Error> {
                try performGenericTextRecognition(on: image, configuration: configuration)
            }

            let genericText = try? genericResult.get()

            switch configuration.mode {
            case .generic:
                return try genericResult.get()
            case .automatic:
                let imageData = try? Data(contentsOf: imageURL)

                guard let imageData else {
                    return try genericResult.get()
                }

                if #available(macOS 26.0, *) {
                    let structuredExtractor = StructuredDocumentExtractor(configuration: configuration)

                    do {
                        if let preferredText = try await structuredExtractor.extractPreferredText(from: imageData, fallbackText: genericText) {
                            return preferredText
                        }
                    } catch {
                        if let genericText {
                            return genericText
                        }

                        throw error
                    }
                }

                return try genericResult.get()
            case .structured:
                let imageData = try? Data(contentsOf: imageURL)

                guard let imageData else {
                    return try genericResult.get()
                }

                if #available(macOS 26.0, *) {
                    let structuredExtractor = StructuredDocumentExtractor(configuration: configuration)

                    do {
                        if let structuredText = try await structuredExtractor.extractStructuredText(from: imageData) {
                            return structuredText
                        }
                    } catch {
                        if let genericText {
                            return genericText
                        }

                        throw error
                    }
                }

                return try genericResult.get()
            }
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
    let mode: OCRMode
    let preserveLineBreaks: Bool
    let recognitionLanguages: [String]
    let customWords: [String]
}
