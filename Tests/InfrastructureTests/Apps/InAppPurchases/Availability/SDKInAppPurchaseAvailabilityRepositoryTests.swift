@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import Infrastructure
@testable import Domain

@Suite
struct SDKInAppPurchaseAvailabilityRepositoryTests {

    @Test func `getAvailability injects iapId and maps territories with currency`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(InAppPurchaseAvailabilityResponse(
            data: InAppPurchaseAvailability(
                type: .inAppPurchaseAvailabilities,
                id: "avail-1",
                attributes: .init(isAvailableInNewTerritories: true),
                relationships: .init(availableTerritories: .init(data: [
                    .init(type: .territories, id: "USA"),
                    .init(type: .territories, id: "CHN"),
                ]))
            ),
            included: [
                Territory(type: .territories, id: "USA", attributes: .init(currency: "USD")),
                Territory(type: .territories, id: "CHN", attributes: .init(currency: "CNY")),
            ],
            links: .init(this: "")
        ))

        let repo = SDKInAppPurchaseAvailabilityRepository(client: stub)
        let result = try await repo.getAvailability(iapId: "iap-99")

        #expect(result.id == "avail-1")
        #expect(result.iapId == "iap-99")
        #expect(result.isAvailableInNewTerritories == true)
        #expect(result.territories.count == 2)
        #expect(result.territories[0].id == "USA")
        #expect(result.territories[0].currency == "USD")
        #expect(result.territories[1].id == "CHN")
        #expect(result.territories[1].currency == "CNY")
    }

    @Test func `getAvailability maps empty territories when relationship data is nil`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(InAppPurchaseAvailabilityResponse(
            data: InAppPurchaseAvailability(
                type: .inAppPurchaseAvailabilities,
                id: "avail-2",
                attributes: .init(isAvailableInNewTerritories: false)
            ),
            links: .init(this: "")
        ))

        let repo = SDKInAppPurchaseAvailabilityRepository(client: stub)
        let result = try await repo.getAvailability(iapId: "iap-1")

        #expect(result.territories.isEmpty)
        #expect(result.isAvailableInNewTerritories == false)
    }

    @Test func `createAvailability injects iapId into response`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(InAppPurchaseAvailabilityResponse(
            data: InAppPurchaseAvailability(
                type: .inAppPurchaseAvailabilities,
                id: "avail-new",
                attributes: .init(isAvailableInNewTerritories: true),
                relationships: .init(availableTerritories: .init(data: [
                    .init(type: .territories, id: "USA"),
                ]))
            ),
            included: [
                Territory(type: .territories, id: "USA", attributes: .init(currency: "USD")),
            ],
            links: .init(this: "")
        ))

        let repo = SDKInAppPurchaseAvailabilityRepository(client: stub)
        let result = try await repo.createAvailability(
            iapId: "iap-42",
            isAvailableInNewTerritories: true,
            territoryIds: ["USA"]
        )

        #expect(result.id == "avail-new")
        #expect(result.iapId == "iap-42")
        #expect(result.territories[0].id == "USA")
        #expect(result.territories[0].currency == "USD")
    }
}
