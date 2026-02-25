@preconcurrency import AppStoreConnect_Swift_SDK
import Domain

public struct SDKPricingRepository: PricingRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func hasPricing(appId: String) async throws -> Bool {
        let request = APIEndpoint.v1.apps.id(appId).appPriceSchedule.get()
        do {
            _ = try await client.request(request)
            return true
        } catch {
            return false
        }
    }
}
