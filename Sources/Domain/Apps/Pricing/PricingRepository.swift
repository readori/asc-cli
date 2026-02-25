import Mockable

@Mockable
public protocol PricingRepository: Sendable {
    func hasPricing(appId: String) async throws -> Bool
}
