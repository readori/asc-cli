import Testing
@testable import Domain

@Suite
struct AppAvailabilityTests {

    @Test func `app availability carries app id as parent`() {
        let availability = MockRepositoryFactory.makeAppAvailability(
            id: "avail-1",
            appId: "app-42"
        )
        #expect(availability.appId == "app-42")
    }

    @Test func `app availability includes per-territory statuses`() {
        let availability = MockRepositoryFactory.makeAppAvailability(
            territories: [
                MockRepositoryFactory.makeAppTerritoryAvailability(territoryId: "USA", isAvailable: true),
                MockRepositoryFactory.makeAppTerritoryAvailability(territoryId: "CHN", isAvailable: false),
            ]
        )
        #expect(availability.territories.count == 2)
        #expect(availability.territories[0].isAvailable == true)
        #expect(availability.territories[1].isAvailable == false)
    }

    @Test func `affordances include get app availability`() {
        let availability = MockRepositoryFactory.makeAppAvailability(appId: "app-42")
        #expect(availability.affordances["getAvailability"] == "asc app-availability get --app-id app-42")
    }

    @Test func `affordances include list territories`() {
        let availability = MockRepositoryFactory.makeAppAvailability()
        #expect(availability.affordances["listTerritories"] == "asc territories list")
    }
}
