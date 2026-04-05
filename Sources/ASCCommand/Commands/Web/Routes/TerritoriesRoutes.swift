import Hummingbird
import HummingbirdWebSocket
import ASCPlugin
import Infrastructure

/// /api/v1/territories — Territory routes.
enum TerritoriesRoutes {
    static func register(on group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/territories") { _, _ -> Response in
            do {
                let repo = try ClientProvider.makeTerritoryRepository()
                let output = try await RESTHandlers.listTerritories(repo: repo)
                return restResponse(output)
            } catch {
                return jsonError("Failed to list territories: \(error.localizedDescription)", status: .internalServerError)
            }
        }
    }
}
