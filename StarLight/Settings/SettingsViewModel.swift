import Foundation
import SwiftUI
import CocoaCoordinator

final class SettingsViewModel: ViewModel<SettingsRoute>, ObservableObject {
    func logout() {
        appServices.loginService.logout()
        router.trigger(.logout)
    }
}
