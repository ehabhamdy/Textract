import AppKit

@MainActor
final class StatusItemController: NSObject {
    private let appController: AppController
    private let statusItem: NSStatusItem

    init(appController: AppController) {
        self.appController = appController
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        configureStatusButton()
        configureMenu()
    }

    private func configureStatusButton() {
        guard let button = statusItem.button else {
            return
        }

        if let image = NSImage(systemSymbolName: "text.viewfinder", accessibilityDescription: "Text Extractor") {
            image.isTemplate = true
            button.image = image
        } else {
            button.title = "Tx"
        }

        button.toolTip = "Text Extractor"
    }

    private func configureMenu() {
        let menu = NSMenu()
        menu.autoenablesItems = false

        let captureItem = NSMenuItem(title: "Capture Text", action: #selector(captureText), keyEquivalent: "")
        captureItem.target = self

        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self

        let quitItem = NSMenuItem(title: "Quit Text Extractor", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self

        menu.items = [captureItem, .separator(), settingsItem, .separator(), quitItem]
        statusItem.menu = menu
    }

    @objc private func captureText() {
        appController.captureText()
    }

    @objc private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
