import Foundation
import Testing
@testable import StarLightCore

struct PersonalRepositoriesRefreshPolicyTests {
    @Test
    func refreshesWithoutPreviousRefreshDate() {
        #expect(PersonalRepositoriesRefreshPolicy.shouldRefresh(
            lastFullRefreshDate: nil,
            currentDate: Date(timeIntervalSince1970: 1_000),
            minimumFullRefreshInterval: 100
        ))
    }

    @Test
    func refreshesOnceTheMinimumIntervalHasElapsed() {
        #expect(PersonalRepositoriesRefreshPolicy.shouldRefresh(
            lastFullRefreshDate: Date(timeIntervalSince1970: 900),
            currentDate: Date(timeIntervalSince1970: 1_000),
            minimumFullRefreshInterval: 100
        ))
    }

    @Test
    func skipsRefreshWithinTheMinimumInterval() {
        #expect(!PersonalRepositoriesRefreshPolicy.shouldRefresh(
            lastFullRefreshDate: Date(timeIntervalSince1970: 901),
            currentDate: Date(timeIntervalSince1970: 1_000),
            minimumFullRefreshInterval: 100
        ))
    }
}
