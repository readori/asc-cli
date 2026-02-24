@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import Infrastructure
@testable import Domain

@Suite
struct SDKVersionRepositoryTests {

    @Test func `listVersions injects appId into each version`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppStoreVersionsResponse(
            data: [
                AppStoreVersion(
                    type: .appStoreVersions,
                    id: "v-1",
                    attributes: .init(platform: .ios, versionString: "1.0.0", appStoreState: .readyForSale)
                ),
                AppStoreVersion(
                    type: .appStoreVersions,
                    id: "v-2",
                    attributes: .init(platform: .macOs, versionString: "1.0.0", appStoreState: .prepareForSubmission)
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKVersionRepository(client: stub)
        let result = try await repo.listVersions(appId: "app-42")

        #expect(result.count == 2)
        #expect(result.allSatisfy { $0.appId == "app-42" })
    }

    @Test func `listVersions maps versionString and platform`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppStoreVersionsResponse(
            data: [
                AppStoreVersion(
                    type: .appStoreVersions,
                    id: "v-1",
                    attributes: .init(platform: .ios, versionString: "2.3.0", appStoreState: .readyForSale)
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKVersionRepository(client: stub)
        let result = try await repo.listVersions(appId: "app-1")

        #expect(result[0].versionString == "2.3.0")
        #expect(result[0].platform == .iOS)
    }
}
