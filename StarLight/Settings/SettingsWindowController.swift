import AppKit
import UIFoundation

final class SettingsWindow: NSWindow {}

final class SettingsWindowController: XiblessWindowController<SettingsWindow> {
    /// Nudges the window left of true center. The settings form is visually left-heavy — labels
    /// on the left, short controls on the right — so a geometrically centered window reads as if
    /// it sat too far right. 25pt is 5% of the 500pt content width.
    private static let horizontalCenterOffset: CGFloat = 100

    override func windowDidLoad() {
        super.windowDidLoad()

        // The window is created with a zero content rect and only reaches its real size once
        // SwiftUI's preferredContentSize turns into constraints. Constraint-driven resizes keep
        // the window's anchor point fixed, and that anchor defaults to the top-left corner, so
        // centering alone would pin the top-left corner to the screen center. Anchoring both axes
        // to the center keeps the window centered as it grows, with no dependency on when the
        // content settles. See Documentations/WindowSizingAndPlacement.md.
        contentWindow.setAnchorAttribute(.centerX, for: .horizontal)
        contentWindow.setAnchorAttribute(.centerY, for: .vertical)
        contentWindow.box.centerInScreen()

        // Applied after centering, and stable as the window grows: the center anchor carries the
        // offset along instead of recomputing the origin from the new size.
        contentWindow.setFrameOrigin(
            NSPoint(
                x: contentWindow.frame.origin.x - Self.horizontalCenterOffset,
                y: contentWindow.frame.origin.y
            )
        )

        contentWindow.toolbar = NSToolbar()
        contentWindow.title = "Settings"
    }
}
