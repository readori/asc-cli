@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import Infrastructure
@testable import Domain

@Suite
struct SDKReviewDetailRepositoryTests {

    @Test func `getReviewDetail injects versionId and maps contact fields`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppStoreReviewDetailResponse(
            data: AppStoreConnect_Swift_SDK.AppStoreReviewDetail(
                type: .appStoreReviewDetails,
                id: "rd-1",
                attributes: .init(
                    contactFirstName: "Jane",
                    contactLastName: "Smith",
                    contactPhone: "+1-555-0100",
                    contactEmail: "jane@example.com",
                    demoAccountName: nil,
                    demoAccountPassword: nil,
                    isDemoAccountRequired: false,
                    notes: nil
                )
            ),
            links: .init(this: "")
        ))

        let repo = SDKReviewDetailRepository(client: stub)
        let result = try await repo.getReviewDetail(versionId: "v-42")

        #expect(result.id == "rd-1")
        #expect(result.versionId == "v-42")
        #expect(result.contactFirstName == "Jane")
        #expect(result.contactLastName == "Smith")
        #expect(result.contactPhone == "+1-555-0100")
        #expect(result.contactEmail == "jane@example.com")
        #expect(result.demoAccountRequired == false)
    }

    @Test func `getReviewDetail maps demoAccount fields`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppStoreReviewDetailResponse(
            data: AppStoreConnect_Swift_SDK.AppStoreReviewDetail(
                type: .appStoreReviewDetails,
                id: "rd-2",
                attributes: .init(
                    contactFirstName: nil,
                    contactLastName: nil,
                    contactPhone: nil,
                    contactEmail: nil,
                    demoAccountName: "demo_user",
                    demoAccountPassword: "secret123",
                    isDemoAccountRequired: true,
                    notes: nil
                )
            ),
            links: .init(this: "")
        ))

        let repo = SDKReviewDetailRepository(client: stub)
        let result = try await repo.getReviewDetail(versionId: "v-99")

        #expect(result.demoAccountRequired == true)
        #expect(result.demoAccountName == "demo_user")
        #expect(result.demoAccountPassword == "secret123")
        #expect(result.hasContact == false)
    }
}
