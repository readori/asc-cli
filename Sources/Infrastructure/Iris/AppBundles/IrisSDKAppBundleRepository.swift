import Domain
import Foundation

/// Implements `IrisAppBundleRepository` via the iris private API.
public struct IrisSDKAppBundleRepository: IrisAppBundleRepository, @unchecked Sendable {
    private let client: IrisClient

    public init(client: IrisClient = IrisClient()) {
        self.client = client
    }

    public func listAppBundles(session: IrisSession) async throws -> [AppBundle] {
        let (data, _) = try await client.get(
            path: "appBundles",
            queryItems: [
                URLQueryItem(name: "include", value: "appBundleVersions"),
                URLQueryItem(name: "limit", value: "300"),
            ],
            cookies: session.cookies
        )
        let response = try JSONDecoder().decode(IrisAppBundlesResponse.self, from: data)
        return response.data.map { mapToAppBundle($0) }
    }

    public func createApp(
        session: IrisSession,
        name: String,
        bundleId: String,
        sku: String,
        primaryLocale: String,
        platforms: [String]
    ) async throws -> AppBundle {
        let requestBody = IrisCreateAppRequest(
            data: .init(
                type: "appBundles",
                attributes: .init(
                    name: name,
                    bundleId: bundleId,
                    sku: sku,
                    primaryLocale: primaryLocale
                ),
                relationships: .init(
                    platforms: .init(
                        data: platforms.map { .init(id: $0, type: "platforms") }
                    )
                )
            )
        )
        let body = try JSONEncoder().encode(requestBody)
        let (data, _) = try await client.post(
            path: "appBundles",
            body: body,
            cookies: session.cookies
        )
        let response = try JSONDecoder().decode(IrisSingleAppBundleResponse.self, from: data)
        return mapToAppBundle(response.data)
    }

    private func mapToAppBundle(_ resource: IrisAppBundleResource) -> AppBundle {
        AppBundle(
            id: resource.id,
            name: resource.attributes.name ?? "",
            bundleId: resource.attributes.bundleId ?? "",
            sku: resource.attributes.sku ?? "",
            primaryLocale: resource.attributes.primaryLocale ?? "en-US",
            platforms: resource.attributes.platformNames ?? []
        )
    }
}

// MARK: - Iris JSON:API Models

struct IrisAppBundlesResponse: Decodable {
    let data: [IrisAppBundleResource]
}

struct IrisSingleAppBundleResponse: Decodable {
    let data: IrisAppBundleResource
}

struct IrisAppBundleResource: Decodable {
    let id: String
    let type: String
    let attributes: IrisAppBundleAttributes
}

struct IrisAppBundleAttributes: Decodable {
    let name: String?
    let bundleId: String?
    let sku: String?
    let primaryLocale: String?
    let platformNames: [String]?
}

// MARK: - Create App Request

struct IrisCreateAppRequest: Encodable {
    let data: IrisCreateAppData

    struct IrisCreateAppData: Encodable {
        let type: String
        let attributes: IrisCreateAppAttributes
        let relationships: IrisCreateAppRelationships
    }

    struct IrisCreateAppAttributes: Encodable {
        let name: String
        let bundleId: String
        let sku: String
        let primaryLocale: String
    }

    struct IrisCreateAppRelationships: Encodable {
        let platforms: IrisPlatformRelationship
    }

    struct IrisPlatformRelationship: Encodable {
        let data: [IrisPlatformData]
    }

    struct IrisPlatformData: Encodable {
        let id: String
        let type: String
    }
}
