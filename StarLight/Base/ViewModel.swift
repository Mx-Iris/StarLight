import Foundation
import CocoaCoordinator

class ViewModel<Route: Routable> {
    let appServices: AppServices
    unowned let router: any Router<Route>

    init(appServices: AppServices, router: any Router<Route>) {
        self.appServices = appServices
        self.router = router
    }
}
