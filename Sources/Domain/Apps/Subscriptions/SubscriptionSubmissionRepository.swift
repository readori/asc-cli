import Mockable

@Mockable
public protocol SubscriptionSubmissionRepository: Sendable {
    func submitSubscription(subscriptionId: String) async throws -> SubscriptionSubmission
}
