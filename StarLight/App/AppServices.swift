//
//  AppServices.swift
//  StarLight
//
//  Created by JH on 2024/12/31.
//

import Foundation
import Defaults
import StarLightCore

final class AppServices {
    let loginService = LoginService()

    let starredRepositoriesService = StarredRepositoriesService()

    let personalRepositoriesService = PersonalRepositoriesService()

    init() {
        applyStoredPreferences()
    }

    /// Both services start on their own built-in defaults, so whatever the user last chose has to
    /// be pushed back in at launch. `PersonalRepositoriesService` in particular stays inert until
    /// it is told it is enabled, which keeps a user who never turns the feature on from ever
    /// causing a request.
    private func applyStoredPreferences() {
        let refreshInterval = Defaults[.repositoriesRefreshInterval]
        let searchPersonalRepositories = Defaults[.searchPersonalRepositories]

        Task {
            await starredRepositoriesService.setRefreshInterval(refreshInterval)
            await personalRepositoriesService.setRefreshInterval(refreshInterval)
            await personalRepositoriesService.setEnabled(searchPersonalRepositories)
        }
    }
}
