import Foundation
import Testing
@testable import StarLightCore

struct AuthenticationFailureReporterTests {
    @Test
    func treatsMissingMessageAsSomethingOtherThanAuthenticationFailure() {
        #expect(!AuthenticationFailureReporter.isAuthenticationFailure(message: nil))
    }

    @Test(arguments: [
        "Bad credentials",
        "Requires authentication",
        "Resource not accessible by personal access token",
    ])
    func recognizesTokenRejectionMessages(message: String) {
        #expect(AuthenticationFailureReporter.isAuthenticationFailure(message: message))
    }

    @Test
    func matchesRegardlessOfCase() {
        #expect(AuthenticationFailureReporter.isAuthenticationFailure(message: "bad credentials"))
    }

    @Test
    func matchesWhenTheMessageCarriesExtraContext() {
        #expect(AuthenticationFailureReporter.isAuthenticationFailure(
            message: "Bad credentials. The token may have expired."
        ))
    }

    @Test
    func leavesUnrelatedFailuresAlone() {
        // Rate limiting must not log the user out.
        #expect(!AuthenticationFailureReporter.isAuthenticationFailure(message: "API rate limit exceeded"))
        #expect(!AuthenticationFailureReporter.isAuthenticationFailure(message: "Not Found"))
    }
}
