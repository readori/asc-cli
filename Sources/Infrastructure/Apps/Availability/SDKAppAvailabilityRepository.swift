@preconcurrency import AppStoreConnect_Swift_SDK
import Domain

public struct SDKAppAvailabilityRepository: AppAvailabilityRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func getAppAvailability(appId: String) async throws -> Domain.AppAvailability {
        let request = APIEndpoint.v1.apps.id(appId).appAvailabilityV2.get(parameters: .init(
            fieldsTerritoryAvailabilities: [.available, .releaseDate, .preOrderEnabled, .preOrderPublishDate, .contentStatuses, .territory],
            include: [.territoryAvailabilities],
            limitTerritoryAvailabilities: 200
        ))
        let response = try await client.request(request)
        let territories = (response.included ?? []).compactMap { mapTerritoryAvailability($0) }
        return Domain.AppAvailability(
            id: response.data.id,
            appId: appId,
            isAvailableInNewTerritories: response.data.attributes?.isAvailableInNewTerritories ?? false,
            territories: territories
        )
    }

    private func mapTerritoryAvailability(
        _ sdk: AppStoreConnect_Swift_SDK.TerritoryAvailability
    ) -> Domain.AppTerritoryAvailability? {
        guard let territoryId = sdk.relationships?.territory?.data?.id else { return nil }
        let contentStatuses = (sdk.attributes?.contentStatuses ?? []).compactMap { sdkStatus in
            Domain.ContentStatus(rawValue: sdkStatus.rawValue)
        }
        return Domain.AppTerritoryAvailability(
            id: sdk.id,
            territoryId: territoryId,
            isAvailable: sdk.attributes?.isAvailable ?? false,
            releaseDate: sdk.attributes?.releaseDate,
            isPreOrderEnabled: sdk.attributes?.isPreOrderEnabled ?? false,
            contentStatuses: contentStatuses
        )
    }
}
