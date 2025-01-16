import AppKit
import GitHubModels
import CocoaCoordinator

enum LoginRoute: Routable {
    case login
    case logged
}

typealias LoginTransition = SceneTransition<LoginWindowController, LoginViewController>

final class LoginCoordinator: SceneCoordinator<LoginRoute, LoginTransition> {
    protocol Delegate: AnyObject {
        func loginCoordinatorDidLogin(_ coordinator: LoginCoordinator)
    }

    let appServices: AppServices

    weak var delegate: Delegate?

    init(appServices: AppServices) {
        self.appServices = appServices
        super.init(windowController: .init(), initialRoute: nil)
    }

    override func prepareTransition(for route: LoginRoute) -> LoginTransition {
        switch route {
        case .login:
            let viewModel = LoginViewModel(appServices: appServices, router: self)
            let viewController = LoginViewController(viewModel: viewModel)
            return .show(viewController)
        case .logged:
            return .close()
        }
    }

    override func completeTransition(for route: LoginRoute) {
        super.completeTransition(for: route)
        switch route {
        case .login:
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
        case .logged:
            delegate?.loginCoordinatorDidLogin(self)
        }
    }
}
