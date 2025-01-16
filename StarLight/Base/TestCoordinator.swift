import CocoaCoordinator

class TestCoordinator<Route: Routable>: Coordinator<Route, AppTransition> {
    
    override func prepareTransition(for route: Route) -> AppTransition {
        return .none()
    }
}
