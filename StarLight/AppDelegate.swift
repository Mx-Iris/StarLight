//
//  AppDelegate.swift
//  StarLight
//
//  Created by JH on 2024/12/29.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    let appServices = AppServices()
    
    @IBOutlet var window: NSWindow!


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }


}

