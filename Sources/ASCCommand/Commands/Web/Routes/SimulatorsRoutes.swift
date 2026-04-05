import Hummingbird
import HummingbirdWebSocket
import ASCPlugin
import Infrastructure

/// /api/v1/simulators — Simulator routes.
enum SimulatorsRoutes {
    static func register(on group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/simulators") { _, _ -> Response in
            let repo = ClientProvider.makeSimulatorRepository()
            do {
                let output = try await RESTHandlers.listSimulators(repo: repo)
                return restResponse(output)
            } catch {
                return jsonError("Failed to list simulators: \(error.localizedDescription)", status: .internalServerError)
            }
        }
    }
}
