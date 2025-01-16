import AppKit
import UIFoundation

final class SettingsWindow: NSWindow {}

final class SettingsWindowController: XiblessWindowController<SettingsWindow> {
    override func windowDidLoad() {
        super.windowDidLoad()

        contentWindow.setFrame(.init(x: 0, y: 0, width: 500, height: 300), display: false)
        contentWindow.box.positionCenter()
        contentWindow.toolbar = NSToolbar()
        contentWindow.title = "Settings"
    }
}
