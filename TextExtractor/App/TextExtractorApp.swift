import SwiftUI

@main
struct TextExtractorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView(appController: .shared)
        } label: {
            Label("Text Extractor", systemImage: "text.viewfinder")
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView()
                .frame(width: 460)
                .onAppear {
                    NSApp.activate(ignoringOtherApps: true)
                }
        }
    }
}
