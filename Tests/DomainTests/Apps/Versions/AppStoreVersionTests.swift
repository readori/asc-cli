import Foundation
import Testing
@testable import Domain

@Suite
struct AppStoreVersionTests {

    @Test
    func `version carries parent appId`() {
        let version = MockRepositoryFactory.makeVersion(id: "v1", appId: "app-1")
        #expect(version.appId == "app-1")
    }

    @Test
    func `readyForSale version is live`() {
        let version = MockRepositoryFactory.makeVersion(state: .readyForSale)
        #expect(version.isLive == true)
        #expect(version.isEditable == false)
        #expect(version.isPending == false)
    }

    @Test
    func `prepareForSubmission version is editable`() {
        let version = MockRepositoryFactory.makeVersion(state: .prepareForSubmission)
        #expect(version.isLive == false)
        #expect(version.isEditable == true)
        #expect(version.isPending == false)
    }

    @Test
    func `inReview version is pending`() {
        let version = MockRepositoryFactory.makeVersion(state: .inReview)
        #expect(version.isPending == true)
        #expect(version.isEditable == false)
    }

    @Test
    func `displayName combines platform and version string`() {
        let version = MockRepositoryFactory.makeVersion(
            versionString: "2.1.0",
            platform: .iOS
        )
        #expect(version.displayName == "iOS 2.1.0")
    }

    @Test(arguments: zip(
        AppStorePlatform.allCases,
        ["iOS", "macOS", "tvOS", "watchOS", "visionOS"]
    ))
    func `platform displayName is human readable`(platform: AppStorePlatform, expected: String) {
        #expect(platform.displayName == expected)
    }

    @Test(arguments: zip(
        ["ios", "macos", "tvos", "watchos", "visionos"],
        AppStorePlatform.allCases
    ))
    func `platform cliArgument parses all platforms`(arg: String, expected: AppStorePlatform) {
        #expect(AppStorePlatform(cliArgument: arg) == expected)
    }

    @Test
    func `unknown platform cliArgument returns nil`() {
        #expect(AppStorePlatform(cliArgument: "unknown") == nil)
    }
}
