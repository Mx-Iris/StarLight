//
//  MainView.swift
//  StarLight
//
//  Created by JH on 2025/1/3.
//

import Foundation
import SwiftUI
import KeyboardShortcuts

final class SettingsViewController: XiblessHostingController<SettingsView> {
    init() {
        super.init(rootView: .init())
    }
}

struct SettingsView: View {
    var body: some View {
        KeyboardShortcuts.Recorder("StarLight Hotkeys", name: .main)
            .frame(width: 500, height: 300)
    }
}


#Preview {
    SettingsView()
}
