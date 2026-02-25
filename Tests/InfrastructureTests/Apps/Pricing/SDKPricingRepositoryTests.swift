@preconcurrency import AppStoreConnect_Swift_SDK
import Foundation
import Testing
@testable import Infrastructure
@testable import Domain

@Suite
struct SDKPricingRepositoryTests {

    @Test func `hasPricing returns true when price schedule exists`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppPriceScheduleResponse(
            data: AppPriceSchedule(
                type: .appPriceSchedules,
                id: "ps-1"
            ),
            links: .init(this: "")
        ))

        let repo = SDKPricingRepository(client: stub)
        let result = try await repo.hasPricing(appId: "app-1")
        #expect(result == true)
    }

    @Test func `hasPricing returns false when request throws`() async throws {
        let stub = ThrowingStubAPIClient()

        let repo = SDKPricingRepository(client: stub)
        let result = try await repo.hasPricing(appId: "app-no-pricing")
        #expect(result == false)
    }
}

/// A stub client that always throws an error, used to simulate missing resources.
private final class ThrowingStubAPIClient: APIClient, @unchecked Sendable {
    func request<T: Decodable>(_ endpoint: Request<T>) async throws -> T {
        throw URLError(.badServerResponse)
    }
    func request(_ endpoint: Request<Void>) async throws {
        throw URLError(.badServerResponse)
    }
}
