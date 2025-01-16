import Foundation
import KeyboardShortcuts
import LaunchAtLogin
import Luminare
import SwiftUI

class TestSettingsCoordinator: TestCoordinator<SettingsRoute> {}

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

    var body: some View {
        VStack {
            Form {
                Section {
                    KeyboardShortcuts.Recorder("StarLight Hotkeys", name: .main)

                    Toggle(isOn: Settings.$showRepositoryDescription) {
                        Text("Show Repository Description")
                    }

                    Toggle(isOn: Settings.$showSettingsOnLaunch) {
                        Text("Show Settings on Launch")
                    }

                    LaunchAtLogin.Toggle()

                    Stepper(value: viewModel.refreshIntervalBinding, format: .number) {
                        Text("Repositories Refresh Interval (minutes)")
                    }
                    

                } footer: {
                    HStack {
                        Spacer()
                        Button {
                            viewModel.logout()
                        } label: {
                            Text("Logout")
                        }
                        .buttonStyle(LuminareCompactButtonStyle())
                        Spacer()
                    }
                }
            }
            .formStyle(.grouped)
            .frame(width: 500, height: 300)
        }
    }
}

#Preview {
    SettingsView(viewModel: .init(appServices: .init(), router: TestSettingsCoordinator(initialRoute: nil)))
}
