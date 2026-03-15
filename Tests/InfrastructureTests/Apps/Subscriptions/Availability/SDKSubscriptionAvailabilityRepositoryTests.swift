@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import Infrastructure
@testable import Domain

@Suite
struct SDKSubscriptionAvailabilityRepositoryTests {

    @Test func `getAvailability injects subscriptionId and maps territories with currency`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionAvailabilityResponse(
            data: SubscriptionAvailability(
                type: .subscriptionAvailabilities,
                id: "avail-1",
                attributes: .init(isAvailableInNewTerritories: true),
                relationships: .init(availableTerritories: .init(data: [
                    .init(type: .territories, id: "USA"),
                    .init(type: .territories, id: "GBR"),
                ]))
            ),
            included: [
                Territory(type: .territories, id: "USA", attributes: .init(currency: "USD")),
                Territory(type: .territories, id: "GBR", attributes: .init(currency: "GBP")),
            ],
            links: .init(this: "")
        ))

        let repo = SDKSubscriptionAvailabilityRepository(client: stub)
        let result = try await repo.getAvailability(subscriptionId: "sub-99")

        #expect(result.id == "avail-1")
        #expect(result.subscriptionId == "sub-99")
        #expect(result.territories.count == 2)
        #expect(result.territories[0].id == "USA")
        #expect(result.territories[0].currency == "USD")
        #expect(result.territories[1].id == "GBR")
        #expect(result.territories[1].currency == "GBP")
    }

    @Test func `getAvailability maps empty territories when relationship data is nil`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionAvailabilityResponse(
            data: SubscriptionAvailability(
                type: .subscriptionAvailabilities,
                id: "avail-2",
                attributes: .init(isAvailableInNewTerritories: false)
            ),
            links: .init(this: "")
        ))

        let repo = SDKSubscriptionAvailabilityRepository(client: stub)
        let result = try await repo.getAvailability(subscriptionId: "sub-1")

        #expect(result.territories.isEmpty)
    }

    @Test func `createAvailability injects subscriptionId and maps included territories`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionAvailabilityResponse(
            data: SubscriptionAvailability(
                type: .subscriptionAvailabilities,
                id: "avail-new",
                attributes: .init(isAvailableInNewTerritories: false),
                relationships: .init(availableTerritories: .init(data: [
                    .init(type: .territories, id: "JPN"),
                ]))
            ),
            included: [
                Territory(type: .territories, id: "JPN", attributes: .init(currency: "JPY")),
            ],
            links: .init(this: "")
        ))

        let repo = SDKSubscriptionAvailabilityRepository(client: stub)
        let result = try await repo.createAvailability(
            subscriptionId: "sub-42",
            isAvailableInNewTerritories: false,
            territoryIds: ["JPN"]
        )

        #expect(result.id == "avail-new")
        #expect(result.subscriptionId == "sub-42")
        #expect(result.territories[0].id == "JPN")
        #expect(result.territories[0].currency == "JPY")
    }
}
