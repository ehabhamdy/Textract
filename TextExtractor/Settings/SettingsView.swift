import KeyboardShortcuts
import SwiftUI

struct SettingsView: View {
    @AppStorage(PreferenceKeys.playSuccessSound) private var playSuccessSound = true
    @AppStorage(PreferenceKeys.preserveLineBreaks) private var preserveLineBreaks = true
    @AppStorage(PreferenceKeys.recognitionLanguages) private var recognitionLanguages = "en-US, ar"
    @AppStorage(PreferenceKeys.customWords) private var customWords = ""
    @StateObject private var launchAtLoginController = LaunchAtLoginController()

    var body: some View {
        Form {
            Section("Shortcut") {
                KeyboardShortcuts.Recorder("Capture selected text", name: .captureSelection)

                Text("Assign a shortcut to trigger screen capture from any app.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("OCR") {
                TextField("Recognition languages", text: $recognitionLanguages)

                Text("Comma-separated BCP 47 language codes, for example: en-US, ar, de-DE. Arabic works best when `ar` is included.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Toggle("Preserve line breaks", isOn: $preserveLineBreaks)
                Toggle("Play success sound", isOn: $playSuccessSound)

                TextField("Custom words", text: $customWords, axis: .vertical)
                    .lineLimit(3...5)

                Text("Add comma-separated product names or jargon to improve OCR quality.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("App") {
                Toggle("Launch at login", isOn: launchAtLoginBinding)

                if let errorMessage = launchAtLoginController.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Button("Capture Now") {
                    AppController.shared.captureText()
                }
            }
        }
        .formStyle(.grouped)
        .padding(20)
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { launchAtLoginController.isEnabled },
            set: { launchAtLoginController.update(isEnabled: $0) }
        )
    }
}
