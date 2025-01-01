#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit
import UIFoundation

final class LoginWindow: NSWindow {}

final class LoginWindowController: XiblessWindowController<LoginWindow> {
    
    static let defaultRect = CGRect(x: 0, y: 0, width: 550, height: 300)
    
    init() {
        super.init(windowGenerator: LoginWindow(contentRect: Self.defaultRect, styleMask: [.titled, .closable, .fullSizeContentView, .miniaturizable], backing: .buffered, defer: false))
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        contentWindow.setFrame(Self.defaultRect, display: false)
        contentWindow.box.positionCenter()
        contentWindow.titleVisibility = .hidden
        contentWindow.titlebarAppearsTransparent = true
        contentWindow.delegate = self
    }
}

extension LoginWindowController: NSWindowDelegate {}

#endif
