//
//  Settings.swift
//  StarLight
//
//  Created by JH on 2025/1/5.
//

import Foundation
import SwiftUI
import StarLightUtilities

enum Settings {
    @AppStorage("showRepositoryDescription")
    static var showRepositoryDescription: Bool = false
    
    
    @AppStorage("showSettingsOnLaunch")
    static var showSettingsOnLaunch: Bool = true
}
