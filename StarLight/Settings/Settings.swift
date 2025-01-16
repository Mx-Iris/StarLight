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
}
