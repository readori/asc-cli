import Mockable

@Mockable
public protocol ReviewDetailRepository: Sendable {
    func getReviewDetail(versionId: String) async throws -> AppStoreReviewDetail
}
