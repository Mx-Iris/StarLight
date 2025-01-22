import Foundation
import SwiftUI
import StarLightUtilities
import Dependencies
import Defaults

extension Defaults.Keys {
    static let showRepositoryDescription = Defaults.Key("showRepositoryDescription", default: false)
    static let showSettingsOnLaunch = Defaults.Key("showSettingsOnLaunch", default: true)
    static let repositoriesRefreshInterval = Defaults.Key<Double>("repositoriesRefreshInterval", default: 15.0)
    static let windowWidth = Defaults.Key<Double>("windowWidth", default: (NSScreen.main?.frame.width ?? (640 * 4)) / 4.0)
    static let windowHeight = Defaults.Key<Double>("windowHeight", default: (NSScreen.main?.frame.height ?? (320 * 4)) / 4.0)
    static let mainAction = Defaults.Key("mainAction", default: MainAction.openURL)
}
