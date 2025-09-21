import Foundation
import SwiftUI
import CocoaCoordinator

final class SettingsViewModel: ViewModel<SettingsRoute>, ObservableObject {
    var refreshIntervalBinding: Binding<TimeInterval> {
        .init {
            self.appServices.repositoriesService.refreshInterval
        } set: {
            self.appServices.repositoriesService.setRefreshInterval($0)
        }
    }

    func logout() {
        appServices.loginService.logout()
        router.trigger(.logout)
    }
}
