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
        // GET /api/v1 — HATEOAS entry point listing all available resources
        router.get("/api/v1") { _, _ -> Response in
            do {
                let output = try RESTHandlers.apiRoot()
                return jsonUTF8Response(output)
            } catch {
                return jsonError("Failed to build API root: \(error.localizedDescription)", status: .internalServerError)
            }
        }

        let group = router.group("/api/v1")

        // MARK: - Apps

        group.get("/apps") { _, _ -> Response in
            do {
                let repo = try ClientProvider.makeAppRepository()
                let output = try await RESTHandlers.listApps(repo: repo)
                return jsonUTF8Response(output)
            } catch {
                return jsonError("Failed to list apps: \(error.localizedDescription)", status: .internalServerError)
            }
        }

        group.get("/apps/:appId") { _, context -> Response in
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

        // MARK: - Versions

        group.get("/apps/:appId/versions") { _, context -> Response in
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

        // MARK: - Builds

        group.get("/apps/:appId/builds") { _, context -> Response in
            guard let appId = context.parameters.get("appId") else {
                return jsonError("Missing appId parameter")
            }
            do {
                let repo = try ClientProvider.makeBuildRepository()
                let output = try await RESTHandlers.listBuilds(appId: appId, repo: repo)
                return jsonUTF8Response(output)
            } catch {
                return jsonError("Failed to list builds: \(error.localizedDescription)", status: .internalServerError)
            }
        }

        // MARK: - TestFlight

        group.get("/apps/:appId/testflight") { _, context -> Response in
            guard let appId = context.parameters.get("appId") else {
                return jsonError("Missing appId parameter")
            }
            do {
                let repo = try ClientProvider.makeTestFlightRepository()
                let output = try await RESTHandlers.listBetaGroups(appId: appId, repo: repo)
                return jsonUTF8Response(output)
            } catch {
                return jsonError("Failed to list beta groups: \(error.localizedDescription)", status: .internalServerError)
            }
        }

        // MARK: - Code Signing

        group.get("/certificates") { _, _ -> Response in
            do {
                let repo = try ClientProvider.makeCertificateRepository()
                let output = try await RESTHandlers.listCertificates(repo: repo)
                return jsonUTF8Response(output)
            } catch {
                return jsonError("Failed to list certificates: \(error.localizedDescription)", status: .internalServerError)
            }
        }

        group.get("/bundle-ids") { _, _ -> Response in
            do {
                let repo = try ClientProvider.makeBundleIDRepository()
                let output = try await RESTHandlers.listBundleIDs(repo: repo)
                return jsonUTF8Response(output)
            } catch {
                return jsonError("Failed to list bundle IDs: \(error.localizedDescription)", status: .internalServerError)
            }
        }

        group.get("/devices") { _, _ -> Response in
            do {
                let repo = try ClientProvider.makeDeviceRepository()
                let output = try await RESTHandlers.listDevices(repo: repo)
                return jsonUTF8Response(output)
            } catch {
                return jsonError("Failed to list devices: \(error.localizedDescription)", status: .internalServerError)
            }
        }

        group.get("/profiles") { _, _ -> Response in
            do {
                let repo = try ClientProvider.makeProfileRepository()
                let output = try await RESTHandlers.listProfiles(repo: repo)
                return jsonUTF8Response(output)
            } catch {
                return jsonError("Failed to list profiles: \(error.localizedDescription)", status: .internalServerError)
            }
        }

        // MARK: - Simulators

        group.get("/simulators") { _, _ -> Response in
            let repo = ClientProvider.makeSimulatorRepository()
            do {
                let output = try await RESTHandlers.listSimulators(repo: repo)
                return jsonUTF8Response(output)
            } catch {
                return jsonError("Failed to list simulators: \(error.localizedDescription)", status: .internalServerError)
            }
        }

        // MARK: - Plugins

        group.get("/plugins") { _, _ -> Response in
            let repo = ClientProvider.makePluginRepository()
            do {
                let output = try await RESTHandlers.listPlugins(repo: repo)
                return jsonUTF8Response(output)
            } catch {
                return jsonError("Failed to list plugins: \(error.localizedDescription)", status: .internalServerError)
            }
        }

        // MARK: - Territories

        group.get("/territories") { _, _ -> Response in
            do {
                let repo = try ClientProvider.makeTerritoryRepository()
                let output = try await RESTHandlers.listTerritories(repo: repo)
                return jsonUTF8Response(output)
            } catch {
                return jsonError("Failed to list territories: \(error.localizedDescription)", status: .internalServerError)
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
