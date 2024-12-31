import AppKit
import SwiftUI
import Luminare

final class LoginViewController: NSHostingController<LoginView> {
    
    
    init(viewModel: LoginViewModel) {
        super.init(rootView: .init(viewModel: viewModel))
    }
    
    @MainActor @preconcurrency required dynamic init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}


struct LoginView: View {
    
    @ObservedObject var viewModel: LoginViewModel
    
    var body: some View {
        VStack {
            Text("Welcome to StarLight")
                .font(.largeTitle)
            Button {
                viewModel.login()
            } label: {
                Text("Login")
            }
            .buttonStyle(LuminareCompactButtonStyle())
            .frame(width: 80, height: 30)
        }
    }
}

@available(macOS 14.0, *)
#Preview {
    LoginView(viewModel: .init(router: TestCoordinator(initialRoute: nil)))
        .frame(width: 550, height: 300)
}
