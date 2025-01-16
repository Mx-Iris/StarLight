import AppKit
import SwiftUI
import Luminare
import StarLightUI

final class LoginViewController: XiblessHostingController<LoginView> {
    let viewModel: LoginViewModel

    init(viewModel: LoginViewModel) {
        self.viewModel = viewModel
        super.init(rootView: .init(viewModel: viewModel))
    }
}

struct LoginView: View {
    @ObservedObject
    var viewModel: LoginViewModel

    var body: some View {
        VStack(spacing: 30) {
            Text("Welcome to StarLight")
                .font(.largeTitle)

            AsyncButton {
                try await viewModel.login()
            } label: {
                Text("Login")
            }
            .buttonStyle(LuminareCompactButtonStyle())
        }
        .frame(width: 550, height: 300)
    }
}

class TestLoginCoordinator: TestCoordinator<LoginRoute> {}

#Preview {
    LoginView(viewModel: .init(appServices: .init(), router: TestLoginCoordinator(initialRoute: nil)))
}
