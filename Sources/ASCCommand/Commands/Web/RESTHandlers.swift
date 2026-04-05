import Domain
import Foundation

/// Shared handler logic for REST API endpoints.
/// Each method takes an injected repository, calls the domain layer directly,
/// and formats the response using OutputFormatter in REST mode.
enum RESTHandlers {

    static func listApps(repo: any AppRepository, limit: Int? = nil) async throws -> String {
        let response = try await repo.listApps(limit: limit)
        let formatter = OutputFormatter(format: .json, pretty: true)
        return try formatter.formatAgentItems(
            response.data,
            headers: [],
            rowMapper: { _ in [] },
            affordanceMode: .rest
        )
    }

    static func getApp(id: String, repo: any AppRepository) async throws -> String {
        let app = try await repo.getApp(id: id)
        let formatter = OutputFormatter(format: .json, pretty: true)
        return try formatter.formatAgentItems(
            [app],
            headers: [],
            rowMapper: { _ in [] },
            affordanceMode: .rest
        )
    }

    static func listVersions(appId: String, repo: any VersionRepository) async throws -> String {
        let versions = try await repo.listVersions(appId: appId)
        let formatter = OutputFormatter(format: .json, pretty: true)
        return try formatter.formatAgentItems(
            versions,
            headers: [],
            rowMapper: { _ in [] },
            affordanceMode: .rest
        )
    }
}