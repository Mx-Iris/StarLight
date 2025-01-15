//
//  MainView.swift
//  StarLight
//
//  Created by JH on 2025/1/3.
//

import Foundation
import SwiftUI
import KeyboardShortcuts
import Luminare

class TestSettingsCoordinator: TestCoordinator<SettingsRoute> {
    
}


final class SettingsViewModel: ViewModel<SettingsRoute>, ObservableObject {
    func logout() {
        appServices.loginService.logout()
        router.trigger(.logout)
    }
}


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
