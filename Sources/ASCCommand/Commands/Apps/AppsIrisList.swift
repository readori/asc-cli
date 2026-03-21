import ArgumentParser
import Domain

struct AppsIrisList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "iris-list",
        abstract: "List all apps via iris private API (cookie-based auth)"
    )

    @OptionGroup var globals: GlobalOptions

    func run() async throws {
        let cookieProvider = ClientProvider.makeIrisCookieProvider()
        let repo = ClientProvider.makeIrisAppBundleRepository()
        print(try await execute(cookieProvider: cookieProvider, repo: repo))
    }

    func execute(
        cookieProvider: any IrisCookieProvider,
        repo: any IrisAppBundleRepository
    ) async throws -> String {
        let session = try cookieProvider.resolveSession()
        let apps = try await repo.listAppBundles(session: session)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            apps,
            headers: ["ID", "Name", "Bundle ID", "SKU", "Platforms"],
            rowMapper: { [$0.id, $0.name, $0.bundleId, $0.sku, $0.platforms.joined(separator: ",")] }
        )
    }
}
