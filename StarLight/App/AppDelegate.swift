import Cocoa

@MainActor
@main
class AppDelegate: NSObject, NSApplicationDelegate {
    let appServices = AppServices()

    lazy var appCoordinator = AppCoordinator(appServices: appServices)

    lazy var statusItemController = AppStatusItemController(appServices: appServices, router: appCoordinator)

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        _ = appCoordinator
        _ = statusItemController
    }

    func applicationWillTerminate(_ aNotification: Notification) {}

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
