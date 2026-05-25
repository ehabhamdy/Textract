import Foundation
import Vision

@available(macOS 26.0, *)
struct StructuredDocumentExtractor: Sendable {
    private struct StructuredDocumentOutput {
        let text: String
        let hasTable: Bool
        let paragraphCount: Int
    }

    private let configuration: OCRConfiguration

    init(configuration: OCRConfiguration) {
        self.configuration = configuration
    }

    func extractPreferredText(from imageData: Data, fallbackText: String?) async throws -> String? {
        guard let structuredOutput = try await extractStructuredOutput(from: imageData) else {
            return fallbackText
        }

        guard let fallbackText else {
            return structuredOutput.text
        }

        if shouldPreferStructuredOutput(structuredOutput, over: fallbackText) {
            return structuredOutput.text
        }

        return fallbackText
    }

    private func extractStructuredOutput(from imageData: Data) async throws -> StructuredDocumentOutput? {
        var request = RecognizeDocumentsRequest()
        var textOptions = request.textRecognitionOptions
        textOptions.automaticallyDetectLanguage = true
        textOptions.useLanguageCorrection = true
        textOptions.customWords = configuration.customWords
        textOptions.recognitionLanguages = configuration.recognitionLanguages.map(Locale.Language.init(identifier:))
        request.textRecognitionOptions = textOptions

        let observations = try await request.perform(on: imageData)
        guard let document = observations.first?.document else {
            return nil
        }

        let tableSections = document.tables
            .map(serializeTable)
            .filter { !$0.isEmpty }

        let paragraphSections = document.paragraphs
            .map { normalizeParagraph($0.transcript) }
            .filter { !$0.isEmpty }

        let text: String
        if !tableSections.isEmpty {
            text = tableSections.joined(separator: "\n\n")
        } else if !paragraphSections.isEmpty {
            let separator = configuration.preserveLineBreaks ? "\n\n" : " "
            text = paragraphSections.joined(separator: separator)
        } else {
            text = normalizeParagraph(document.text.transcript)
        }

        let normalizedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedText.isEmpty else {
            return nil
        }

        return StructuredDocumentOutput(
            text: normalizedText,
            hasTable: !tableSections.isEmpty,
            paragraphCount: paragraphSections.count
        )
    }

    private func shouldPreferStructuredOutput(_ structuredOutput: StructuredDocumentOutput, over fallbackText: String) -> Bool {
        let normalizedFallback = fallbackText.trimmingCharacters(in: .whitespacesAndNewlines)

        if normalizedFallback.isEmpty {
            return true
        }

        if structuredOutput.hasTable {
            return true
        }

        if structuredOutput.paragraphCount > 1 && configuration.preserveLineBreaks {
            return true
        }

        return false
    }

    private func serializeTable(_ table: DocumentObservation.Container.Table) -> String {
        let rows = table.rows.compactMap { row -> String? in
            let cells = row.map { cell in
                normalizeCell(cell.content.text.transcript)
            }

            guard cells.contains(where: { !$0.isEmpty }) else {
                return nil
            }

            return cells.joined(separator: "\t")
        }

        return rows.joined(separator: "\n")
    }

    private func normalizeParagraph(_ text: String) -> String {
        text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func normalizeCell(_ text: String) -> String {
        text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}