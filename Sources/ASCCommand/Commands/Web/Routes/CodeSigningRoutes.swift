import Hummingbird
import HummingbirdWebSocket
import ASCPlugin
import Infrastructure

/// /api/v1/certificates, bundle-ids, devices, profiles — Code signing routes.
enum CodeSigningRoutes {
    static func register(on group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/certificates") { _, _ -> Response in
            do {
                let repo = try ClientProvider.makeCertificateRepository()
                let output = try await RESTHandlers.listCertificates(repo: repo)
                return restResponse(output)
            } catch {
                return jsonError("Failed to list certificates: \(error.localizedDescription)", status: .internalServerError)
            }
        }

        group.get("/bundle-ids") { _, _ -> Response in
            do {
                let repo = try ClientProvider.makeBundleIDRepository()
                let output = try await RESTHandlers.listBundleIDs(repo: repo)
                return restResponse(output)
            } catch {
                return jsonError("Failed to list bundle IDs: \(error.localizedDescription)", status: .internalServerError)
            }
        }

        group.get("/devices") { _, _ -> Response in
            do {
                let repo = try ClientProvider.makeDeviceRepository()
                let output = try await RESTHandlers.listDevices(repo: repo)
                return restResponse(output)
            } catch {
                return jsonError("Failed to list devices: \(error.localizedDescription)", status: .internalServerError)
            }
        }

        group.get("/profiles") { _, _ -> Response in
            do {
                let repo = try ClientProvider.makeProfileRepository()
                let output = try await RESTHandlers.listProfiles(repo: repo)
                return restResponse(output)
            } catch {
                return jsonError("Failed to list profiles: \(error.localizedDescription)", status: .internalServerError)
            }
        }
    }
}
