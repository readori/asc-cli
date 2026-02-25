import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct VersionsCheckReadinessTests {

    // MARK: - Helpers

    private func makeEditable(buildId: String? = "build-55") -> AppStoreVersion {
        AppStoreVersion(
            id: "v-123",
            appId: "app-456",
            versionString: "1.2.0",
            platform: .iOS,
            state: .prepareForSubmission,
            buildId: buildId
        )
    }

    private func makeBuild() -> Build {
        Build(id: "build-55", version: "1.2.0", expired: false, processingState: .valid, buildNumber: "55")
    }

    private func makeReviewDetail(phone: String? = "+1-555-0100", email: String? = "dev@example.com") -> AppStoreReviewDetail {
        AppStoreReviewDetail(
            id: "rd-1",
            versionId: "v-123",
            contactPhone: phone,
            contactEmail: email,
            demoAccountRequired: false
        )
    }

    private func makeLocalization() -> AppStoreVersionLocalization {
        AppStoreVersionLocalization(
            id: "loc-1",
            versionId: "v-123",
            locale: "en-US",
            description: "App description",
            keywords: "app, tool"
        )
    }

    private func makeScreenshotSet() -> AppScreenshotSet {
        AppScreenshotSet(
            id: "set-1",
            localizationId: "loc-1",
            screenshotDisplayType: .iphone67,
            screenshotsCount: 3
        )
    }

    // MARK: - Tests

    @Test func `execute returns ready when all checks pass`() async throws {
        let mockVersionRepo = MockVersionRepository()
        let mockBuildRepo = MockBuildRepository()
        let mockReviewDetailRepo = MockReviewDetailRepository()
        let mockLocalizationRepo = MockVersionLocalizationRepository()
        let mockScreenshotRepo = MockScreenshotRepository()
        let mockPricingRepo = MockPricingRepository()

        given(mockVersionRepo).getVersion(id: .value("v-123")).willReturn(makeEditable())
        given(mockBuildRepo).getBuild(id: .value("build-55")).willReturn(makeBuild())
        given(mockPricingRepo).hasPricing(appId: .value("app-456")).willReturn(true)
        given(mockReviewDetailRepo).getReviewDetail(versionId: .value("v-123")).willReturn(makeReviewDetail())
        given(mockLocalizationRepo).listLocalizations(versionId: .value("v-123")).willReturn([makeLocalization()])
        given(mockScreenshotRepo).listScreenshotSets(localizationId: .value("loc-1")).willReturn([makeScreenshotSet()])

        let cmd = try VersionsCheckReadiness.parse(["--version-id", "v-123", "--pretty"])
        let output = try await cmd.execute(
            versionRepo: mockVersionRepo,
            buildRepo: mockBuildRepo,
            reviewDetailRepo: mockReviewDetailRepo,
            localizationRepo: mockLocalizationRepo,
            screenshotRepo: mockScreenshotRepo,
            pricingRepo: mockPricingRepo
        )

        #expect(output.contains("\"isReadyToSubmit\" : true"))
        #expect(output.contains("\"submit\" : \"asc versions submit --version-id v-123\""))
        #expect(output.contains("\"linked\" : true"))
        #expect(output.contains("\"buildVersion\" : \"1.2.0 (55)\""))
    }

    @Test func `execute not ready when no build linked`() async throws {
        let mockVersionRepo = MockVersionRepository()
        let mockBuildRepo = MockBuildRepository()
        let mockReviewDetailRepo = MockReviewDetailRepository()
        let mockLocalizationRepo = MockVersionLocalizationRepository()
        let mockScreenshotRepo = MockScreenshotRepository()
        let mockPricingRepo = MockPricingRepository()

        given(mockVersionRepo).getVersion(id: .value("v-123")).willReturn(makeEditable(buildId: nil))
        given(mockPricingRepo).hasPricing(appId: .value("app-456")).willReturn(true)
        given(mockReviewDetailRepo).getReviewDetail(versionId: .value("v-123")).willReturn(makeReviewDetail())
        given(mockLocalizationRepo).listLocalizations(versionId: .value("v-123")).willReturn([])

        let cmd = try VersionsCheckReadiness.parse(["--version-id", "v-123", "--pretty"])
        let output = try await cmd.execute(
            versionRepo: mockVersionRepo,
            buildRepo: mockBuildRepo,
            reviewDetailRepo: mockReviewDetailRepo,
            localizationRepo: mockLocalizationRepo,
            screenshotRepo: mockScreenshotRepo,
            pricingRepo: mockPricingRepo
        )

        #expect(output.contains("\"isReadyToSubmit\" : false"))
        #expect(output.contains("\"linked\" : false"))
        #expect(!output.contains("\"submit\""))
    }

    @Test func `execute not ready when state not editable`() async throws {
        let mockVersionRepo = MockVersionRepository()
        let mockBuildRepo = MockBuildRepository()
        let mockReviewDetailRepo = MockReviewDetailRepository()
        let mockLocalizationRepo = MockVersionLocalizationRepository()
        let mockScreenshotRepo = MockScreenshotRepository()
        let mockPricingRepo = MockPricingRepository()

        let liveVersion = AppStoreVersion(
            id: "v-123",
            appId: "app-456",
            versionString: "1.0.0",
            platform: .iOS,
            state: .readyForSale,
            buildId: "build-55"
        )
        given(mockVersionRepo).getVersion(id: .value("v-123")).willReturn(liveVersion)
        given(mockBuildRepo).getBuild(id: .value("build-55")).willReturn(makeBuild())
        given(mockPricingRepo).hasPricing(appId: .value("app-456")).willReturn(true)
        given(mockReviewDetailRepo).getReviewDetail(versionId: .value("v-123")).willReturn(makeReviewDetail())
        given(mockLocalizationRepo).listLocalizations(versionId: .value("v-123")).willReturn([])

        let cmd = try VersionsCheckReadiness.parse(["--version-id", "v-123", "--pretty"])
        let output = try await cmd.execute(
            versionRepo: mockVersionRepo,
            buildRepo: mockBuildRepo,
            reviewDetailRepo: mockReviewDetailRepo,
            localizationRepo: mockLocalizationRepo,
            screenshotRepo: mockScreenshotRepo,
            pricingRepo: mockPricingRepo
        )

        #expect(output.contains("\"isReadyToSubmit\" : false"))
        #expect(output.contains("READY_FOR_SALE"))
    }

    @Test func `execute shows reviewContactCheck fail when contact missing`() async throws {
        let mockVersionRepo = MockVersionRepository()
        let mockBuildRepo = MockBuildRepository()
        let mockReviewDetailRepo = MockReviewDetailRepository()
        let mockLocalizationRepo = MockVersionLocalizationRepository()
        let mockScreenshotRepo = MockScreenshotRepository()
        let mockPricingRepo = MockPricingRepository()

        given(mockVersionRepo).getVersion(id: .value("v-123")).willReturn(makeEditable())
        given(mockBuildRepo).getBuild(id: .value("build-55")).willReturn(makeBuild())
        given(mockPricingRepo).hasPricing(appId: .value("app-456")).willReturn(true)
        // No contact info
        given(mockReviewDetailRepo).getReviewDetail(versionId: .value("v-123")).willReturn(
            makeReviewDetail(phone: nil, email: nil)
        )
        given(mockLocalizationRepo).listLocalizations(versionId: .value("v-123")).willReturn([])

        let cmd = try VersionsCheckReadiness.parse(["--version-id", "v-123", "--pretty"])
        let output = try await cmd.execute(
            versionRepo: mockVersionRepo,
            buildRepo: mockBuildRepo,
            reviewDetailRepo: mockReviewDetailRepo,
            localizationRepo: mockLocalizationRepo,
            screenshotRepo: mockScreenshotRepo,
            pricingRepo: mockPricingRepo
        )

        // reviewContactCheck failing is SHOULD FIX only — does not block isReadyToSubmit
        #expect(output.contains("\"isReadyToSubmit\" : true"))
        #expect(output.contains("No contact email or phone set"))
    }
}
