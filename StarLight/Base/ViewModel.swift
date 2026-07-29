import Foundation
import CocoaCoordinator

/// Every concrete view model is `@MainActor`, so the base class is too — otherwise a subclass
/// initializer cannot touch its own main-actor state.
@MainActor
class ViewModel<Route: Routable> {
    let appServices: AppServices
    
    unowned let router: any Router<Route>

    init(appServices: AppServices, router: any Router<Route>) {
        self.appServices = appServices
        self.router = router
    }
}
