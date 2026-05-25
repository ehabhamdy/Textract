import Foundation

protocol TextExtractionEngine: Sendable {
    func extractText(from imageURL: URL) async throws -> String
}

enum TextExtractionError: LocalizedError, Equatable {
    case captureCancelled
    case captureFailed(String)
    case imageLoadFailed
    case noTextFound

    var errorDescription: String? {
        switch self {
        case .captureCancelled:
            return "Capture cancelled."
        case let .captureFailed(message):
            return message
        case .imageLoadFailed:
            return "The selected image could not be loaded for OCR."
        case .noTextFound:
            return "No text was detected in the selected region."
        }
    }
}
