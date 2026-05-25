import CoreGraphics
import Foundation
import Vision

struct TextPostProcessor {
    private struct RecognizedFragment {
        let text: String
        let boundingBox: CGRect
    }

    private let preserveLineBreaks: Bool
    private let lineThreshold: CGFloat = 0.025

    init(preserveLineBreaks: Bool) {
        self.preserveLineBreaks = preserveLineBreaks
    }

    func process(_ observations: [VNRecognizedTextObservation]) -> String {
        let fragments = observations.compactMap { observation -> RecognizedFragment? in
            guard let candidate = observation.topCandidates(1).first else {
                return nil
            }

            let normalizedText = normalizeFragment(candidate.string)
            guard !normalizedText.isEmpty else {
                return nil
            }

            return RecognizedFragment(text: normalizedText, boundingBox: observation.boundingBox)
        }

        guard !fragments.isEmpty else {
            return ""
        }

        let sortedFragments = fragments.sorted { left, right in
            let verticalDistance = abs(left.boundingBox.midY - right.boundingBox.midY)
            if verticalDistance > lineThreshold {
                return left.boundingBox.midY > right.boundingBox.midY
            }

            return left.boundingBox.minX < right.boundingBox.minX
        }

        var lines: [[RecognizedFragment]] = []

        for fragment in sortedFragments {
            if let lastIndex = lines.indices.last,
               let anchor = lines[lastIndex].first,
               abs(anchor.boundingBox.midY - fragment.boundingBox.midY) <= lineThreshold {
                lines[lastIndex].append(fragment)
            } else {
                lines.append([fragment])
            }
        }

        let assembledLines = lines.map { line in
            line.sorted { $0.boundingBox.minX < $1.boundingBox.minX }
                .map(\.text)
                .joined(separator: " ")
        }

        if preserveLineBreaks {
            return assembledLines.joined(separator: "\n")
        }

        return assembledLines.joined(separator: " ")
    }

    private func normalizeFragment(_ text: String) -> String {
        text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
