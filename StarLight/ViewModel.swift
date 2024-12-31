import Foundation
import CocoaCoordinator

class ViewModel<Route: Routable> {
    unowned let router: any Router<Route>

    init(router: any Router<Route>) {
        self.router = router
    }
}



class TestCoordinator<Route: Routable>: Coordinator<Route, AppTransition> {}
