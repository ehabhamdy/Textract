import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItemController: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppPreferences.registerDefaults()
        statusItemController = StatusItemController(appController: .shared)
    }
}
