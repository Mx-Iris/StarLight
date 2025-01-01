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

    lazy var appCoordinator = AppCoordinator(appServices: appServices)

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        _ = appCoordinator
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
