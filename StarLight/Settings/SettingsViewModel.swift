import AppKit
import Foundation
import SwiftUI
import CocoaCoordinator
import StarLightCore

@MainActor
final class SettingsViewModel: ViewModel<SettingsRoute>, ObservableObject {
    func logout() {
        appServices.loginService.logout()
        router.trigger(.logout)
    }

    func manageAuthorizationsOnGitHub() {
        NSWorkspace.shared.open(LoginService.manageAuthorizationURL)
    }
}
