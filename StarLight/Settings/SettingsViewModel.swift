import Foundation
import SwiftUI
import CocoaCoordinator

final class SettingsViewModel: ViewModel<SettingsRoute>, ObservableObject {
    var refreshIntervalBinding: Binding<TimeInterval> {
        .init {
            self.appServices.store.refreshInterval
        } set: {
            self.appServices.store.refreshInterval = $0
        }
    }

    func logout() {
        appServices.loginService.logout()
        router.trigger(.logout)
    }
}
