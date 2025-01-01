import AppKit
import SwiftUI
import Luminare

final class LoginViewController: NSHostingController<LoginView> {
    let viewModel: LoginViewModel
    init(viewModel: LoginViewModel) {
        self.viewModel = viewModel
        var loginView = LoginView()
        loginView.loginButtonClicked = { [weak viewModel] in
            guard let viewModel else { return }
            viewModel.login()
        }
        super.init(rootView: loginView)
    }

    @available(*, unavailable)
    @MainActor @preconcurrency dynamic required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct LoginView: View {
    
    var loginButtonClicked: (() -> Void)?

    var body: some View {
        VStack(spacing: 50) {
            Text("Welcome to StarLight")
                .font(.largeTitle)
            Button {
                loginButtonClicked?()
            } label: {
                Text("Login")
            }
            .buttonStyle(LuminareCompactButtonStyle())
            .frame(width: 80, height: 30)
        }
        .frame(width: 550, height: 300)
    }
}

#Preview {
    LoginView(loginButtonClicked: nil)
}
