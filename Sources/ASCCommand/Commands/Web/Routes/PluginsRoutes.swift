import Hummingbird
import HummingbirdWebSocket
import ASCPlugin
import Infrastructure

/// /api/v1/plugins — Plugin routes.
enum PluginsRoutes {
    static func register(on group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/plugins") { _, _ -> Response in
            let repo = ClientProvider.makePluginRepository()
            do {
                let output = try await RESTHandlers.listPlugins(repo: repo)
                return restResponse(output)
            } catch {
                return jsonError("Failed to list plugins: \(error.localizedDescription)", status: .internalServerError)
            }
        }
    }
}
