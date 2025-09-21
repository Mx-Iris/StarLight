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
    var mainAction

    @Default(.windowWidth)
    var windowWidth

    @Default(.windowHeight)
    var windowHeight

    @Default(.showSettingsOnLaunch)
    var showSettingsOnLaunch

    @Default(.showRepositoryDescription)
    var showRepositoryDescription

    @Default(.repositoriesRefreshInterval)
    var repositoriesRefreshInterval

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
                        Task {
                            await viewModel.appServices.repositoriesService.setRefreshInterval(newValue)
                        }
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
                    VStack {
                        Spacer(minLength: 20)
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
            }
            .formStyle(.grouped)
            .frame(width: 500)
        }
    }
}

class TestSettingsCoordinator: TestCoordinator<SettingsRoute> {}

#Preview {
    SettingsView(viewModel: .init(appServices: .init(), router: TestSettingsCoordinator(initialRoute: nil)))
}
