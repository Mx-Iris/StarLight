//
//  MainView.swift
//  StarLight
//
//  Created by JH on 2025/1/3.
//

import Foundation
import SwiftUI
import KeyboardShortcuts

final class SettingsViewModel: ViewModel<SettingsRoute> {
    
}


final class SettingsViewController: XiblessHostingController<SettingsView> {
    let viewModel: SettingsViewModel
    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
        super.init(rootView: .init())
    }
}

struct SettingsView: View {
    var body: some View {
        VStack {
            Form {
                Section {
                    KeyboardShortcuts.Recorder("StarLight Hotkeys", name: .main)

                } footer: {
                    Button {} label: {
                        Text("Logout")
                    }
                    Spacer()
                }
            }
            .formStyle(.grouped)
            .frame(width: 500, height: 300)
        }
    }
}

#Preview {
    SettingsView()
}
