import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct IAPOfferCodesCreateTests {

    @Test func `creates IAP offer code and returns it with affordances`() async throws {
        let mockRepo = MockInAppPurchaseOfferCodeRepository()
        given(mockRepo).createOfferCode(
            iapId: .any, name: .any, customerEligibilities: .any
        ).willReturn(InAppPurchaseOfferCode(
            id: "ioc-new",
            iapId: "iap-1",
            name: "BONUS2024",
            customerEligibilities: [.nonSpender, .activeSpender],
            isActive: true
        ))

        let cmd = try IAPOfferCodesCreate.parse([
            "--iap-id", "iap-1",
            "--name", "BONUS2024",
            "--eligibility", "NON_SPENDER",
            "--eligibility", "ACTIVE_SPENDER",
            "--pretty",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("ioc-new"))
        #expect(output.contains("BONUS2024"))
    }

    @Test func `throws for invalid eligibility`() async throws {
        let mockRepo = MockInAppPurchaseOfferCodeRepository()
        let cmd = try IAPOfferCodesCreate.parse([
            "--iap-id", "iap-1",
            "--name", "TEST",
            "--eligibility", "INVALID",
        ])
        await #expect(throws: (any Error).self) {
            try await cmd.execute(repo: mockRepo)
        }
    }
}
