import SwiftUI

struct MenuBarContentView: View {
    @Environment(\.openSettings) private var openSettings
    @ObservedObject var appController: AppController

    var body: some View {
        Button("Capture Text") {
            appController.captureText()
        }
        .disabled(appController.isProcessing)

        Button("Settings...") {
            NSApp.activate(ignoringOtherApps: true)
            openSettings()
        }

        Divider()

        Button("Quit Text Extractor") {
            NSApp.terminate(nil)
        }
    }
}
