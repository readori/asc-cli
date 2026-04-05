import Hummingbird
import ASCPlugin
import Infrastructure

/// GET /api/v1 — HATEOAS entry point listing all available resources.
enum RootRoutes {
    static func register(on router: ASCRouter) {
        router.get("/api/v1") { _, _ -> Response in
            do {
                let output = try RESTHandlers.apiRoot()
                return restResponse(output)
            } catch {
                return jsonError("Failed to build API root: \(error.localizedDescription)", status: .internalServerError)
            }
        }
    }
}
