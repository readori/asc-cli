import Mockable

@Mockable
public protocol AppAvailabilityRepository: Sendable {
    func getAppAvailability(appId: String) async throws -> AppAvailability
}
