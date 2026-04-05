import Domain
import Hummingbird
import Infrastructure
import ASCPlugin

/// Registers REST API v1 routes on the Hummingbird router.
/// These routes call domain repositories directly (in-process, no subprocess),
/// returning JSON with HATEOAS `_links` for agent navigation.
enum RESTRoutes {

    @Sendable
    static func configure(router: ASCRouter) {
        let group = router.group("/api/v1")

        // GET /api/v1/apps
        group.get("/apps") { request, _ -> Response in
            do {
                let repo = try ClientProvider.makeAppRepository()
                let output = try await RESTHandlers.listApps(repo: repo)
                return jsonUTF8Response(output)
            } catch {
                return jsonError("Failed to list apps: \(error.localizedDescription)", status: .internalServerError)
            }
        }

        // GET /api/v1/apps/:appId
        group.get("/apps/:appId") { request, context -> Response in
            guard let appId = context.parameters.get("appId") else {
                return jsonError("Missing appId parameter")
            }
            do {
                let repo = try ClientProvider.makeAppRepository()
                let output = try await RESTHandlers.getApp(id: appId, repo: repo)
                return jsonUTF8Response(output)
            } catch {
                return jsonError("App not found: \(error.localizedDescription)", status: .notFound)
            }
        }

        // GET /api/v1/apps/:appId/versions
        group.get("/apps/:appId/versions") { request, context -> Response in
            guard let appId = context.parameters.get("appId") else {
                return jsonError("Missing appId parameter")
            }
            do {
                let repo = try ClientProvider.makeVersionRepository()
                let output = try await RESTHandlers.listVersions(appId: appId, repo: repo)
                return jsonUTF8Response(output)
            } catch {
                return jsonError("Failed to list versions: \(error.localizedDescription)", status: .internalServerError)
            }
        }
    }
}

/// Returns a JSON response from a pre-encoded JSON string.
private func jsonUTF8Response(_ json: String, status: HTTPResponse.Status = .ok) -> Response {
    let buffer = ByteBuffer(string: json)
    return Response(
        status: status,
        headers: [.contentType: "application/json; charset=utf-8"],
        body: .init(byteBuffer: buffer)
    )
}