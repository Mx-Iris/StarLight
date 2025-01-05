//
//  MainWindowController.swift
//  StarLight
//
//  Created by JH on 2025/1/3.
//

import AppKit
import UIFoundation

final class SettingsWindow: NSWindow {
}

final class SettingsWindowController: XiblessWindowController<SettingsWindow> {
    
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        contentWindow.setFrame(.init(x: 0, y: 0, width: 500, height: 300), display: false)
        contentWindow.box.positionCenter()
    }
}


