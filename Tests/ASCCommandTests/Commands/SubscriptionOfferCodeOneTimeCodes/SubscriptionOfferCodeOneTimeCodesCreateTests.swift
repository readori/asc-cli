import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct SubscriptionOfferCodeOneTimeCodesCreateTests {

    @Test func `creates one-time codes and returns result with affordances`() async throws {
        let mockRepo = MockSubscriptionOfferCodeRepository()
        given(mockRepo).createOneTimeUseCode(
            offerCodeId: .any, numberOfCodes: .any, expirationDate: .any
        ).willReturn(SubscriptionOfferCodeOneTimeUseCode(
            id: "otc-new",
            offerCodeId: "oc-1",
            numberOfCodes: 500,
            createdDate: "2024-09-01",
            expirationDate: "2025-03-01",
            isActive: true
        ))

        let cmd = try SubscriptionOfferCodeOneTimeCodesCreate.parse([
            "--offer-code-id", "oc-1",
            "--number-of-codes", "500",
            "--expiration-date", "2025-03-01",
            "--pretty",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("otc-new"))
        #expect(output.contains("500"))
    }
}
