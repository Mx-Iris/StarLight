import AppKit
import GitHubModels
import CocoaCoordinator

/// A message shown on the login screen above the sign-in button. Asking the user to authorize again
/// for wider access is a normal request rather than a failure, so the two read differently.
enum LoginNotice: Equatable {
    case failure(String)
    case information(String)

    var message: String {
        switch self {
        case .failure(let message), .information(let message):
            message
        }
    }

    var isFailure: Bool {
        switch self {
        case .failure: true
        case .information: false
        }
    }
}

enum LoginRoute: Routable {
    case login(notice: LoginNotice?)
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
        case .login(let notice):
            let viewModel = LoginViewModel(appServices: appServices, router: self, initialNotice: notice)
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
