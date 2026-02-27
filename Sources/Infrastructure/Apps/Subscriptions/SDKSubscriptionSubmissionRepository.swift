@preconcurrency import AppStoreConnect_Swift_SDK
import Domain

public struct SDKSubscriptionSubmissionRepository: SubscriptionSubmissionRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func submitSubscription(subscriptionId: String) async throws -> Domain.SubscriptionSubmission {
        let body = SubscriptionSubmissionCreateRequest(data: .init(
            type: .subscriptionSubmissions,
            relationships: .init(
                subscription: .init(data: .init(type: .subscriptions, id: subscriptionId))
            )
        ))
        let response = try await client.request(APIEndpoint.v1.subscriptionSubmissions.post(body))
        return Domain.SubscriptionSubmission(id: response.data.id, subscriptionId: subscriptionId)
    }
}
