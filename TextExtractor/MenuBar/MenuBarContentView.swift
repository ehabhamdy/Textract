import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject var appController: AppController

    var body: some View {
        Button("Capture Text") {
            appController.captureText()
        }
        .disabled(appController.isProcessing)

        SettingsLink {
            Text("Settings...")
        }

        Divider()

        Button("Quit Text Extractor") {
            NSApp.terminate(nil)
        }
    }
}