import AppKit
import GitHubModels
import CocoaCoordinator

enum LoginRoute: Routable {
    case login
    case logged(User)
}

typealias LoginTransition = SceneTransition<LoginWindowController, LoginViewController>

final class LoginCoordinator: SceneCoordinator<LoginRoute, LoginTransition> {
    let appServices: AppServices
    init(appServices: AppServices) {
        self.appServices = appServices
        super.init(windowController: .init(), initialRoute: nil)
    }
    
    
    override func prepareTransition(for route: LoginRoute) -> LoginTransition {
        switch route {
        case .login:
            let viewModel = LoginViewModel(router: self)
            let viewController = LoginViewController(viewModel: viewModel)
            return .show(viewController)
        case .logged:
            return .close()
        }
    }
    
    
    override func completeTransition(for route: LoginRoute) {
        super.completeTransition(for: route)
        
    }
}
