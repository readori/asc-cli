import ArgumentParser
import Domain

struct AppAvailabilityGet: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get",
        abstract: "Get territory availability for an app with per-territory status"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App ID to get availability for")
    var appId: String

    func run() async throws {
        let repo = try ClientProvider.makeAppAvailabilityRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any AppAvailabilityRepository) async throws -> String {
        let availability = try await repo.getAppAvailability(appId: appId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [availability],
            headers: ["ID", "App ID", "Available in New Territories", "Territories"],
            rowMapper: {
                let available = $0.territories.filter(\.isAvailable).count
                let total = $0.territories.count
                return [$0.id, $0.appId, String($0.isAvailableInNewTerritories), "\(available)/\(total) available"]
            }
        )
    }
}
