import ArgumentParser
import Domain

struct AppsCreate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create a new app (via iris private API)"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App name")
    var name: String

    @Option(name: .long, help: "Bundle identifier (e.g. com.example.app)")
    var bundleId: String

    @Option(name: .long, help: "SKU identifier")
    var sku: String

    @Option(name: .long, help: "Primary locale (e.g. en-US)")
    var primaryLocale: String = "en-US"

    @Option(name: .long, help: "Platforms (e.g. IOS, MAC_OS)")
    var platforms: [String] = ["IOS"]

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
        let app = try await repo.createApp(
            session: session,
            name: name,
            bundleId: bundleId,
            sku: sku,
            primaryLocale: primaryLocale,
            platforms: platforms
        )
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [app],
            headers: ["ID", "Name", "Bundle ID", "SKU", "Platforms"],
            rowMapper: { [$0.id, $0.name, $0.bundleId, $0.sku, $0.platforms.joined(separator: ",")] }
        )
    }
}
