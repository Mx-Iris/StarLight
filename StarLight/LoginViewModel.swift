import Foundation
import Combine
import CocoaCoordinator

class LoginViewModel: ViewModel<LoginRoute>, ObservableObject {
    func login() {
        Task {
            do {
                try await appServices.loginService.login()
                await MainActor.run {
                    router.trigger(.logged)
                }
            } catch {
                print(error)
            }
        }
    }
}
