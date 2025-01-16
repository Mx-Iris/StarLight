import Foundation
import SwiftUI
import StarLightUtilities

enum Settings {
    @AppStorage("showRepositoryDescription")
    static var showRepositoryDescription: Bool = false

    @AppStorage("showSettingsOnLaunch")
    static var showSettingsOnLaunch: Bool = true
    
    @AppStorage("repositoriesRefreshInterval")
    static var repositoriesRefreshInterval: TimeInterval = 15
    
    @AppStorage("windowWidth")
    static var windowWidth: Double = (NSScreen.main?.frame.width ?? (640 * 4)) / 4.0
    
    @AppStorage("windowHeight")
    static var windowHeight: Double = (NSScreen.main?.frame.height ?? (320 * 4)) / 4.0
}
