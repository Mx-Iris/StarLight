import Foundation
import Combine
import CocoaCoordinator

class LoginViewModel: ViewModel<LoginRoute>, ObservableObject {
    func login() async throws {
        try await appServices.loginService.login()
        await MainActor.run {
            router.trigger(.logged)
        }
    }
}
