import AppKit
import SwiftUI
import GitHubModels
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

            if let deviceCode = viewModel.deviceCode {
                deviceCodeView(deviceCode)
            } else if viewModel.isAuthorizing {
                ProgressView()
                    .scaleEffect(0.7)
                Text("Requesting authorization code…")
                    .font(.callout)
                    .foregroundColor(.secondary)
            } else {
                Button {
                    viewModel.startLogin()
                } label: {
                    Text("Sign in with GitHub")
                        .frame(minWidth: 200)
                }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.callout)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .frame(width: 550, height: 360)
    }

    @ViewBuilder
    private func deviceCodeView(_ deviceCode: DeviceCode) -> some View {
        VStack(spacing: 14) {
            Text("Enter this code on GitHub:")
                .font(.callout)
                .foregroundColor(.secondary)

            Text(deviceCode.userCode)
                .font(.system(size: 36, weight: .semibold, design: .monospaced))
                .tracking(4)
                .textSelection(.enabled)

            Text("The code was copied to your clipboard and your browser was opened to \(deviceCode.verificationURI.absoluteString).")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            HStack(spacing: 16) {
                Button {
                    viewModel.authorizeOnGitHub()
                } label: {
                    Text("Open GitHub again")
                }

                Button(role: .cancel) {
                    viewModel.cancelLogin()
                } label: {
                    Text("Cancel")
                }
            }

            HStack(spacing: 8) {
                ProgressView()
                    .scaleEffect(0.6)
                Text("Waiting for you to authorize…")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
        }
    }
}

class TestLoginCoordinator: TestCoordinator<LoginRoute> {}

#Preview {
    LoginView(viewModel: .init(appServices: .init(), router: TestLoginCoordinator(initialRoute: nil)))
}
