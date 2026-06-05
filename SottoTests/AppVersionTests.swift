import Foundation
import Testing
@testable import SottoKit

@Suite("App Version Tests")
struct AppVersionTests {
    @Test func readsMarketingAndBuildVersionsFromBundleInfo() {
        let version = AppVersion(
            infoDictionary: [
                "CFBundleShortVersionString": "1.2.3",
                "CFBundleVersion": "45",
            ]
        )

        #expect(version.marketingVersion == "1.2.3")
        #expect(version.buildNumber == "45")
        #expect(version.displayString == "1.2.3 (45)")
    }

    @Test func fallsBackWhenBundleVersionValuesAreMissing() {
        let version = AppVersion(infoDictionary: [:])

        #expect(version.marketingVersion == "—")
        #expect(version.buildNumber == "—")
        #expect(version.displayString == "—")
    }
}
