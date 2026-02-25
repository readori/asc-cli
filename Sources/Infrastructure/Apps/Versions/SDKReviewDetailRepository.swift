@preconcurrency import AppStoreConnect_Swift_SDK
import Domain

public struct SDKReviewDetailRepository: ReviewDetailRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func getReviewDetail(versionId: String) async throws -> Domain.AppStoreReviewDetail {
        let request = APIEndpoint.v1.appStoreVersions.id(versionId).appStoreReviewDetail.get()
        let response = try await client.request(request)
        return mapReviewDetail(response.data, versionId: versionId)
    }

    private func mapReviewDetail(
        _ sdk: AppStoreConnect_Swift_SDK.AppStoreReviewDetail,
        versionId: String
    ) -> Domain.AppStoreReviewDetail {
        Domain.AppStoreReviewDetail(
            id: sdk.id,
            versionId: versionId,
            contactFirstName: sdk.attributes?.contactFirstName,
            contactLastName: sdk.attributes?.contactLastName,
            contactPhone: sdk.attributes?.contactPhone,
            contactEmail: sdk.attributes?.contactEmail,
            demoAccountRequired: sdk.attributes?.isDemoAccountRequired ?? false,
            demoAccountName: sdk.attributes?.demoAccountName,
            demoAccountPassword: sdk.attributes?.demoAccountPassword
        )
    }
}
