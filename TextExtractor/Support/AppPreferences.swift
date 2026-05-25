import Foundation

enum PreferenceKeys {
    static let ocrMode = "ocrMode"
    static let playSuccessSound = "playSuccessSound"
    static let preserveLineBreaks = "preserveLineBreaks"
    static let recognitionLanguages = "recognitionLanguages"
    static let customWords = "customWords"
}

enum OCRMode: String, CaseIterable, Sendable {
    case automatic
    case generic
    case structured

    var title: String {
        switch self {
        case .automatic:
            return "Automatic"
        case .generic:
            return "Generic"
        case .structured:
            return "Structured"
        }
    }

    var settingsDescription: String {
        switch self {
        case .automatic:
            return "Balances both OCR engines. Structured OCR is used when it preserves tables or document sections better."
        case .generic:
            return "Always uses the classic text recognizer. Best for simple screenshots and widest compatibility."
        case .structured:
            return "Prioritizes layout-aware OCR for tables and documents on macOS 26+. Falls back to generic OCR when needed."
        }
    }
}

enum AppPreferences {
    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            PreferenceKeys.ocrMode: OCRMode.automatic.rawValue,
            PreferenceKeys.playSuccessSound: true,
            PreferenceKeys.preserveLineBreaks: true,
            PreferenceKeys.recognitionLanguages: "en-US, ar",
            PreferenceKeys.customWords: ""
        ])
    }

    static var ocrMode: OCRMode {
        let rawValue = UserDefaults.standard.string(forKey: PreferenceKeys.ocrMode) ?? OCRMode.automatic.rawValue
        return OCRMode(rawValue: rawValue) ?? .automatic
    }

    static var playSuccessSound: Bool {
        UserDefaults.standard.bool(forKey: PreferenceKeys.playSuccessSound)
    }

    static var preserveLineBreaks: Bool {
        UserDefaults.standard.bool(forKey: PreferenceKeys.preserveLineBreaks)
    }

    static var recognitionLanguages: [String] {
        stringList(forKey: PreferenceKeys.recognitionLanguages, defaultValue: ["en-US", "ar"])
    }

    static var customWords: [String] {
        stringList(forKey: PreferenceKeys.customWords, defaultValue: [])
    }

    private static func stringList(forKey key: String, defaultValue: [String]) -> [String] {
        let rawValue = UserDefaults.standard.string(forKey: key) ?? ""
        let parsedValues = rawValue
            .components(separatedBy: CharacterSet(charactersIn: ",\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return parsedValues.isEmpty ? defaultValue : parsedValues
    }
}
