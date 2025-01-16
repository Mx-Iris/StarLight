//
//  AppDelegate.swift
//  StarLight
//
//  Created by JH on 2024/12/29.
//

import Cocoa

@MainActor
@main
class AppDelegate: NSObject, NSApplicationDelegate {
    let appServices = AppServices()

    lazy var appCoordinator = AppCoordinator(appServices: appServices)
    
    lazy var statusItemController = AppStatusItemController(router: appCoordinator)
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        _ = appCoordinator
        _ = statusItemController
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
