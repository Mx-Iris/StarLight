#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit
import UIFoundation

final class LoginWindow: NSWindow {}

final class LoginWindowController: XiblessWindowController<LoginWindow> {}

#endif
