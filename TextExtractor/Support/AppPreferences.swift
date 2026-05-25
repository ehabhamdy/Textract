import Foundation

enum PreferenceKeys {
    static let playSuccessSound = "playSuccessSound"
    static let preserveLineBreaks = "preserveLineBreaks"
    static let recognitionLanguages = "recognitionLanguages"
    static let customWords = "customWords"
}

enum AppPreferences {
    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            PreferenceKeys.playSuccessSound: true,
            PreferenceKeys.preserveLineBreaks: true,
            PreferenceKeys.recognitionLanguages: "en-US",
            PreferenceKeys.customWords: ""
        ])
    }

    static var playSuccessSound: Bool {
        UserDefaults.standard.bool(forKey: PreferenceKeys.playSuccessSound)
    }

    static var preserveLineBreaks: Bool {
        UserDefaults.standard.bool(forKey: PreferenceKeys.preserveLineBreaks)
    }

    static var recognitionLanguages: [String] {
        stringList(forKey: PreferenceKeys.recognitionLanguages, defaultValue: ["en-US"])
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
