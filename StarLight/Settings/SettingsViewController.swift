import Foundation
import SwiftUI
import Defaults
import LaunchAtLogin
import KeyboardShortcuts

final class SettingsViewController: XiblessHostingController<SettingsView> {
    let viewModel: SettingsViewModel

    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
        super.init(rootView: .init(viewModel: viewModel))
    }
}

struct SettingsView: View {
    @ObservedObject
    var viewModel: SettingsViewModel

    @Default(.mainAction)
    private var mainAction

    @Default(.windowWidth)
    private var windowWidth

    @Default(.windowHeight)
    private var windowHeight

    @Default(.showSettingsOnLaunch)
    private var showSettingsOnLaunch

    @Default(.showRepositoryDescription)
    private var showRepositoryDescription

    @Default(.repositoriesRefreshInterval)
    private var repositoriesRefreshInterval

    @Default(.searchPersonalRepositories)
    private var searchPersonalRepositories

    @Default(.includePrivateRepositories)
    private var includePrivateRepositories

    var body: some View {
        VStack {
            Form {
                Section {
                    KeyboardShortcuts.Recorder("StarLight Hotkeys", name: .main)

                    Toggle(isOn: $showRepositoryDescription) {
                        Text("Show Repository Description")
                    }

                    Toggle(isOn: $showSettingsOnLaunch) {
                        Text("Show Settings on Launch")
                    }

                    LaunchAtLogin.Toggle()

                    Stepper(value: $repositoriesRefreshInterval, format: .number) {
                        Text("Repositories Refresh Interval (minutes)")
                    }
                    .onChange(of: repositoriesRefreshInterval) { newValue in
                        viewModel.repositoriesRefreshIntervalDidChange(to: newValue)
                    }

                    HStack {
                        Stepper("Width", value: $windowWidth, format: .number)

                        Stepper("Height", value: $windowHeight, format: .number)
                    }

                    Picker("Main Action", selection: $mainAction) {
                        Text("Open URL")
                            .tag(MainAction.openURL)
                        Text("Copy URL")
                            .tag(MainAction.copyURL)
                        Text("Open and Copy URL")
                            .tag(MainAction.openAndCopyURL)
                    }

                } footer: {
                    VStack(spacing: 12) {
                        Spacer(minLength: 20)
                        HStack {
                            Spacer()
                            Button {
                                viewModel.manageAuthorizationsOnGitHub()
                            } label: {
                                Text("Manage Authorizations on GitHub")
                            }
                            Spacer()
                        }
                        HStack {
                            Spacer()
                            Button {
                                viewModel.logout()
                            } label: {
                                Text("Logout")
                            }
                            Spacer()
                        }
                    }
                }

                Section {
                    Toggle(isOn: $searchPersonalRepositories) {
                        Text("Search My Repositories")
                        Text("Includes repositories you own and every repository under your organizations.")
                    }
                    .onChange(of: searchPersonalRepositories) { newValue in
                        viewModel.searchPersonalRepositoriesDidChange(to: newValue)
                    }

                    Toggle(isOn: $includePrivateRepositories) {
                        Text("Include Private Repositories")
                        Text("GitHub publishes no read-only scope for private repositories, so this asks for the read/write \"repo\" scope and requires signing in again.")
                    }
                    .onChange(of: includePrivateRepositories) { newValue in
                        viewModel.includePrivateRepositoriesDidChange(to: newValue)
                    }

                    if viewModel.needsReauthorizationForPrivateRepositories {
                        HStack {
                            Label(
                                "Private repositories stay hidden until you authorize the wider access.",
                                systemImage: "exclamationmark.triangle"
                            )
                            .foregroundColor(.secondary)
                            .font(.callout)
                            Spacer()
                            Button {
                                viewModel.reauthorize()
                            } label: {
                                Text("Sign In Again")
                            }
                        }
                    }
                } header: {
                    Text("Repository Sources")
                }
            }
            .formStyle(.grouped)
            .frame(width: 500)
        }
        .alert(
            "Sign in to GitHub again?",
            isPresented: $viewModel.isPresentingPrivateRepositoryAuthorizationAlert
        ) {
            Button("Sign In Again") {
                viewModel.reauthorize()
            }
            Button("Cancel", role: .cancel) {
                viewModel.declinePrivateRepositoryAuthorization()
            }
        } message: {
            Text("Searching private repositories needs GitHub's \"repo\" scope, which also grants write access, plus \"read:org\" to list organizations whose membership you have kept private. StarLight only ever reads.")
        }
    }
}

class TestSettingsCoordinator: TestCoordinator<SettingsRoute> {}

#Preview {
    SettingsView(viewModel: .init(appServices: .init(), router: TestSettingsCoordinator(initialRoute: nil)))
}
