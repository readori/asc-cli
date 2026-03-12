import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct IAPOfferCodeOneTimeCodesCreateTests {

    @Test func `creates IAP one-time codes and returns result with affordances`() async throws {
        let mockRepo = MockInAppPurchaseOfferCodeRepository()
        given(mockRepo).createOneTimeUseCode(
            offerCodeId: .any, numberOfCodes: .any, expirationDate: .any
        ).willReturn(InAppPurchaseOfferCodeOneTimeUseCode(
            id: "iotc-new",
            offerCodeId: "ioc-1",
            numberOfCodes: 400,
            createdDate: "2024-09-01",
            expirationDate: "2025-03-01",
            isActive: true
        ))

        let cmd = try IAPOfferCodeOneTimeCodesCreate.parse([
            "--offer-code-id", "ioc-1",
            "--number-of-codes", "400",
            "--expiration-date", "2025-03-01",
            "--pretty",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("iotc-new"))
        #expect(output.contains("400"))
    }
}
